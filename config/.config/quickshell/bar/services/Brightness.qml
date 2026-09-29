pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Screen backlight through brightnessctl (only laptops have one). Every call prints the new state
// (-m), so `brightness` follows each change, including those made elsewhere before it.
Singleton {
    id: root

    property bool available
    // 0..1
    property real brightness
    readonly property real step: 0.05

    // `arg` is brightnessctl's value: "5%+", "5%-" or "40%".
    function run(arg: string): void {
        const cmd = ["brightnessctl", "-m", "-c", "backlight", "-n", `${Math.round(Theme.brightnessMin * 100)}%`, "set", arg];
        if (proc.running)
            proc.pending = cmd;
        else
            proc.exec(cmd);
    }

    function change(dir: int): void {
        if (available)
            run(`${Math.round(step * 100)}%${dir > 0 ? "+" : "-"}`);
    }

    function set(v: real): void {
        if (available)
            run(`${Math.round(Math.max(Theme.brightnessMin, Math.min(1, v)) * 100)}%`);
    }

    Process {
        id: proc

        property var pending: null

        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true

        // "intel_backlight,backlight,400,40%,1000"
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split("\n")[0]?.split(",") ?? [];
                if (f.length >= 5 && Number(f[4]) > 0) {
                    root.available = true;
                    root.brightness = Number(f[2]) / Number(f[4]);
                }
            }
        }

        onExited: {
            if (pending) {
                const cmd = pending;
                pending = null;
                exec(cmd);
            }
        }
    }
}
