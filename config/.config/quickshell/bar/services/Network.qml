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
    // Saved NetworkManager VPNs: [{ name, uuid, state }], state is "", "activating", "activated" or "deactivating".
    property var vpns: []
    // Number of open popups that want VPN state kept fresh.
    property int vpnWatchers: 0

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
        running: root.vpnWatchers > 0
        repeat: true
        interval: 1000
        onTriggered: root.refreshVpns()
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

        command: ["sh", "-c", 'ip -j -4 addr show dev "$1"; echo; echo ---; nmcli -t -f IN-USE,SSID,SIGNAL,FREQ device wifi list ifname "$1" --rescan no 2>/dev/null | grep "^\\*"; echo ---; grep "$1:" /proc/net/wireless', "sh", root.iface]
        stdout: StdioCollector {
            onStreamFinished: {
                const [addrJson, wifi, wireless] = text.split("---\n");
                const lines = [];

                const wifiFields = wifi?.trim().split(":") ?? [];
                if (wifiFields.length >= 4) {
                    // nmcli -t escapes ':' in SSIDs as '\:'
                    const ssid = wifiFields.slice(1, -2).join(":").replace(/\\/g, "");
                    const dbm = wireless?.trim().split(/\s+/)[3]?.replace(".", "") ?? "?";
                    lines.push(`Network: <big><b>${ssid}</b></big>`);
                    lines.push(`Signal strength: <b>${dbm}dBm (${wifiFields.at(-2)}%)</b>`);
                    lines.push(`Frequency: <b>${wifiFields.at(-1).replace(/\s*MHz/, "")}MHz</b>`);
                }

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
