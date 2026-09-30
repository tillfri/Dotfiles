pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Connection state from the default route; details for the tooltip are fetched on demand.
Singleton {
    id: root

    property string iface
    property string gateway
    readonly property bool connected: iface !== ""
    property string details
    property string localIp
    // Of the default route's device, for the network card; fetched with `details`.
    property bool wifi
    // SSID on wifi, NetworkManager's connection name otherwise.
    property string name
    // Wifi signal 0..100, -1 when not on wifi.
    property int strength: -1
    property string speed
    property string security
    property string dns
    // Visible wifi networks, one per SSID, the connected one first then by signal:
    // [{ ssid, signal, secure, active }].
    property var networks: []
    readonly property bool scanning: networksProc.running
    // SSID being connected to, and the last one that failed (cleared after a moment).
    property string connecting
    property string failed
    // Saved NetworkManager VPNs: [{ name, uuid, state }], state is "", "activating", "activated" or "deactivating".
    property var vpns: []
    // Number of open popups that want the network card's data kept fresh.
    property int watchers: 0

    // Nerd Font wifi strength glyph for a signal of 0..100 (also used for nm-applet's tray icon).
    function signalGlyph(signal: int): string {
        return ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"][Math.max(0, Math.min(4, Math.round(signal / 25)))];
    }

    // nmcli -t escapes ':' as '\:' (and '\' as '\\'); `fields` is the number of fields, the last
    // one (put last in -f for this) keeps whatever is left.
    function splitTerse(line: string, fields: int): list<string> {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (c === ":" && out.length < fields - 1) {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function hexToIp(hex: string): string {
        const bytes = [];
        for (let i = 6; i >= 0; i -= 2)
            bytes.push(parseInt(hex.substr(i, 2), 16));
        return bytes.join(".");
    }

    function cidrToMask(cidr: int): string {
        const mask = [];
        for (let i = 0; i < 4; i++) {
            const bits = Math.max(0, Math.min(8, cidr - i * 8));
            mask.push(256 - Math.pow(2, 8 - bits));
        }
        return mask.join(".");
    }

    function refreshDetails(): void {
        if (connected) {
            detailsProc.running = true;
        } else {
            details = "Disconnected";
            localIp = "";
        }
    }

    function refreshVpns(): void {
        vpnProc.running = true;
    }

    // `rescan`: let NetworkManager scan first if its last scan is older than 30s.
    function refreshNetworks(rescan: bool): void {
        if (networksProc.running)
            return;
        networksProc.rescan = rescan;
        networksProc.running = true;
    }

    // Finds the saved connection for the SSID or creates one; for a new secured network the
    // password is asked by nm-applet's secret agent.
    function connectWifi(ssid: string): void {
        if (connectProc.running)
            return;
        connecting = ssid;
        failed = "";
        connectProc.command = ["nmcli", "device", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    function toggleVpn(uuid: string, active: bool): void {
        if (vpnToggle.running)
            return;
        vpnToggle.pending = {
            uuid,
            state: active ? "deactivating" : "activating"
        };
        vpnToggle.command = ["nmcli", "connection", active ? "down" : "up", "uuid", uuid];
        vpnToggle.running = true;
        vpns = vpns.map(v => v.uuid === uuid ? Object.assign({}, v, {
                state: vpnToggle.pending.state
            }) : v);
    }

    Timer {
        running: true
        repeat: true
        interval: Theme.stateInterval
        onTriggered: route.reload()
    }

    Component.onCompleted: refreshVpns()

    Timer {
        running: root.watchers > 0
        repeat: true
        interval: 1000
        onTriggered: root.refreshVpns()
    }

    Timer {
        running: root.watchers > 0
        repeat: true
        interval: Theme.stateInterval
        onTriggered: root.refreshDetails()
    }

    FileView {
        id: route

        path: "/proc/net/route"
        onLoaded: {
            let best = null;
            for (const line of text().split("\n").slice(1)) {
                const f = line.trim().split(/\s+/);
                if (f.length < 8 || f[1] !== "00000000" || f[7] !== "00000000")
                    continue;
                if (!best || Number(f[6]) < Number(best[6]))
                    best = f;
            }
            root.iface = best?.[0] ?? "";
            root.gateway = best ? root.hexToIp(best[2]) : "";
        }
    }

    Process {
        id: detailsProc

        // Sections: addresses, device type/connection/DNS, the connected wifi row, iw link, wired speed.
        command: ["sh", "-c", `sep() { echo; echo ---; }
ip -j -4 addr show dev "$1"; sep
nmcli -t -f GENERAL.TYPE,GENERAL.CONNECTION,IP4.DNS device show "$1"; sep
nmcli -t -f IN-USE,SIGNAL,RATE,SECURITY,FREQ,SSID device wifi list ifname "$1" --rescan no 2>/dev/null | grep "^\\*"; sep
iw dev "$1" link 2>/dev/null; sep
cat "/sys/class/net/$1/speed" 2>/dev/null`, "sh", root.iface]
        stdout: StdioCollector {
            onStreamFinished: {
                const [addrJson, dev, wifiRow, link, wiredSpeed] = text.split("\n---\n").map(p => p.trim());
                const lines = [];

                const devFields = {};
                for (const line of dev?.split("\n") ?? []) {
                    const i = line.indexOf(":");
                    // IP4.DNS[1] is the primary one
                    const key = line.slice(0, i).replace("[1]", "");
                    if (i > 0 && !(key in devFields))
                        devFields[key] = line.slice(i + 1);
                }
                root.wifi = devFields["GENERAL.TYPE"] === "wifi";
                root.dns = devFields["IP4.DNS"] ?? "";
                root.name = devFields["GENERAL.CONNECTION"] ?? "";
                root.strength = -1;
                root.security = "";
                root.speed = "";

                const [, signal, rate, security, freq, ssid] = wifiRow ? root.splitTerse(wifiRow, 6) : [];
                if (root.wifi && ssid !== undefined) {
                    const dbm = link?.match(/signal: (-?\d+)/)?.[1] ?? "?";
                    root.name = ssid;
                    root.strength = parseInt(signal);
                    root.security = security && security !== "--" ? security : "Open";
                    lines.push(`Network: <big><b>${ssid}</b></big>`);
                    lines.push(`Signal strength: <b>${dbm}dBm (${signal}%)</b>`);
                    lines.push(`Frequency: <b>${freq.replace(/\s*MHz/, "")}MHz</b>`);
                }
                // The negotiated link rate; nmcli's RATE is the access point's maximum.
                const bitrate = link?.match(/tx bitrate: ([\d.]+)/)?.[1];
                if (bitrate)
                    root.speed = `${Math.round(Number(bitrate))} Mbit/s`;
                else if (root.wifi && rate)
                    root.speed = rate;
                else if (Number(wiredSpeed) > 0)
                    root.speed = `${wiredSpeed} Mbit/s`;

                lines.push(`Interface: <b>${root.iface}</b>`);
                root.localIp = "";
                try {
                    const info = JSON.parse(addrJson)[0]?.addr_info?.[0];
                    if (info) {
                        root.localIp = `${info.local}/${info.prefixlen}`;
                        lines.push(`IP: <b>${info.local}/${info.prefixlen}</b>`);
                        lines.push(`Gateway: <b>${root.gateway}</b>`);
                        lines.push(`Netmask: <b>${root.cidrToMask(info.prefixlen)}</b>`);
                    }
                } catch (e) {}
                root.details = lines.join("<br>");
            }
        }
    }

    Process {
        id: networksProc

        property bool rescan

        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", rescan ? "auto" : "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const bySsid = new Map();
                for (const line of text.split("\n")) {
                    const [inUse, signal, security, ssid] = root.splitTerse(line, 4);
                    // Hidden networks have no SSID to show or connect to.
                    if (!ssid)
                        continue;
                    const prev = bySsid.get(ssid);
                    bySsid.set(ssid, {
                        ssid,
                        signal: Math.max(parseInt(signal) || 0, prev?.signal ?? 0),
                        secure: (security !== "" && security !== "--") || (prev?.secure ?? false),
                        active: inUse === "*" || (prev?.active ?? false)
                    });
                }
                root.networks = [...bySsid.values()].sort((a, b) => b.active - a.active || b.signal - a.signal);
            }
        }
    }

    Process {
        id: connectProc

        onExited: code => {
            if (code !== 0)
                root.failed = root.connecting;
            root.connecting = "";
            failedTimer.restart();
            root.refreshNetworks(false);
            root.refreshDetails();
        }
    }

    Timer {
        id: failedTimer

        interval: 4000
        onTriggered: root.failed = ""
    }

    Process {
        id: vpnProc

        command: ["nmcli", "-t", "-f", "TYPE,UUID,STATE,NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const vpns = [];
                for (const line of text.split("\n")) {
                    // NAME is last so escaped ':' in it survive the split
                    const [type, uuid, state, ...name] = line.split(":");
                    if (type === "vpn" || type === "wireguard")
                        vpns.push({
                            name: name.join(":").replace(/\\/g, ""),
                            uuid,
                            // Keep the optimistic state until NM reports the change.
                            state: !state && vpnToggle.pending?.uuid === uuid ? vpnToggle.pending.state : state
                        });
                }
                root.vpns = vpns;
            }
        }
    }

    // `nmcli connection up` blocks until the VPN is up (nm-applet asks for secrets if needed).
    Process {
        id: vpnToggle

        property var pending: null

        onExited: {
            pending = null;
            root.refreshVpns();
            root.refreshDetails();
        }
    }
}
