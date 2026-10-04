pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

// Idle and sleep handling, replacing hypridle (ported from ~/.config/hypr/hypridle.conf): dims the
// backlight (or overlays the screens, modules/IdleDim.qml), then turns the screens off, and locks
// before the system sleeps. Idle inhibitors (the bar's: playing media, the focus timer) hold the
// idle steps off.
Singleton {
    id: root

    property bool enabled: true
    // Past the dim timeout; screens without a backlight show modules/IdleDim.qml.
    property bool dimmed
    // A player other than Theme.idleIgnorePlayers is playing; the bar inhibits idle meanwhile.
    readonly property bool mediaPlaying: Players.players.some(p => p.isPlaying && !Theme.idleIgnorePlayers.some(n => `${p.desktopEntry} ${p.identity}`.toLowerCase().includes(n)))
    // Backlight before dimming; -1 when not dimmed.
    property real dimmedFrom: -1
    // Between logind's PrepareForSleep(true) and the lock screen covering every output.
    property bool sleeping
    // logind object path of this session, for its Lock signal (`loginctl lock-session`).
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") ?? "";
        // sd-bus escaping: anything but [A-Za-z0-9], and a leading digit, becomes _xx.
        const escaped = [...id].map((c, i) => /[A-Za-z]/.test(c) || (i > 0 && /[0-9]/.test(c)) ? c : `_${c.charCodeAt(0).toString(16).padStart(2, "0")}`).join("");
        return id ? `/org/freedesktop/login1/session/${escaped}` : "";
    }

    function dpms(on: bool): void {
        const action = on ? "enable" : "disable";
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.dpms({ action = "${action}" })` : `dpms ${on ? "on" : "off"}`);
    }

    // Lets the suspend go ahead once the lock screen is up.
    function releaseSleep(): void {
        if (sleeping && Lock.secure) {
            sleeping = false;
            inhibitor.stdinEnabled = false;
        }
    }

    // listener { timeout = 270; on-timeout = brightnessctl -s set 10; on-resume = brightnessctl -r }
    // (the lowest the OSD allows, Theme.brightnessMin, rather than a raw 10)
    IdleMonitor {
        enabled: root.enabled
        respectInhibitors: true
        timeout: Theme.idleDim
        onIsIdleChanged: {
            if (isIdle && Brightness.available) {
                root.dimmedFrom = Brightness.brightness;
                Brightness.set(Theme.brightnessMin);
            } else if (!isIdle && root.dimmedFrom >= 0) {
                Brightness.set(root.dimmedFrom);
                root.dimmedFrom = -1;
            }
            root.dimmed = isIdle;
        }
    }

    // listener { timeout = 900; on-timeout = dpms disable; on-resume = dpms enable }
    IdleMonitor {
        enabled: root.enabled
        respectInhibitors: true
        timeout: Theme.idleDpms
        onIsIdleChanged: root.dpms(!isIdle)
    }

    // hypridle's 5h `systemctl shutdown` never worked (no such verb); left out rather than turned
    // into a real poweroff.

    // A delay inhibitor: logind holds a suspend back (up to InhibitDelayMaxSec, 5s) until it is
    // released. `cat` keeps it until its stdin closes, also when quickshell itself goes away.
    Process {
        id: inhibitor

        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=quickshell", "--why=Lock the screen first", "cat"]
        stdinEnabled: true
        running: true
    }

    Connections {
        target: Lock

        function onSecureChanged(): void {
            root.releaseSleep();
        }
    }

    // logind's PrepareForSleep before and after a suspend/hibernate, and this session's Lock.
    Process {
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes(".PrepareForSleep (true")) {
                    root.sleeping = true;
                    Lock.lock();
                    root.releaseSleep();
                } else if (line.includes(".PrepareForSleep (false")) {
                    root.sleeping = false;
                    // hypridle's after_sleep_cmd: no second key press to wake the screens.
                    root.dpms(true);
                    inhibitor.stdinEnabled = true;
                    inhibitor.running = true;
                } else if (line.includes(".Session.Lock ()") && (!root.sessionPath || line.startsWith(`${root.sessionPath}:`))) {
                    Lock.lock();
                }
            }
        }
    }
}
