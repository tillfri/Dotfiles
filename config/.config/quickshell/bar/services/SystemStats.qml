pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// CPU / memory / network logic ported from caelestia's C++ services (cpu.cpp, memory.cpp, networkusage.cpp).
Singleton {
    id: root

    property real cpuPercent: 0
    property real memUsedGiB: 0
    property real temperature: 0
    property real netDown: 0 // bytes/s
    property real netUp: 0

    property var lastCpu: null
    property var lastNet: null
    property string tempPath

    function formatBytes(bytes: real): string {
        const units = ["B", "kB", "MB", "GB"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1000;
            i++;
        }
        const digits = bytes >= 100 || i === 0 ? 0 : bytes >= 10 ? 1 : 2;
        return `${bytes.toFixed(digits)}${units[i]}/s`;
    }

    Timer {
        running: true
        repeat: true
        interval: Theme.stateInterval
        onTriggered: {
            stat.reload();
            meminfo.reload();
            netdev.reload();
            if (root.tempPath)
                temp.reload();
        }
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: {
            const m = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
            if (!m)
                return;
            const vals = m.slice(1, 8).map(Number);
            const total = vals.reduce((a, b) => a + b, 0);
            const idle = vals[3] + vals[4];
            if (root.lastCpu) {
                const dt = total - root.lastCpu.total;
                const di = idle - root.lastCpu.idle;
                if (dt > 0)
                    root.cpuPercent = (1 - di / dt) * 100;
            }
            root.lastCpu = {
                total,
                idle
            };
        }
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const total = Number(t.match(/MemTotal:\s*(\d+)/)?.[1] ?? 0);
            const avail = Number(t.match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
            root.memUsedGiB = Math.max(0, total - avail) / 1024 / 1024;
        }
    }

    FileView {
        id: netdev

        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const line of text().split("\n").slice(2)) {
                const [iface, rest] = line.split(":");
                if (!rest || iface.trim() === "lo")
                    continue;
                const f = rest.trim().split(/\s+/).map(Number);
                rx += f[0];
                tx += f[8];
            }
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.time) / 1000;
                if (dt > 0) {
                    root.netDown = Math.max(0, rx - root.lastNet.rx) / dt;
                    root.netUp = Math.max(0, tx - root.lastNet.tx) / dt;
                }
            }
            root.lastNet = {
                rx,
                tx,
                time: now
            };
        }
    }

    FileView {
        id: temp

        path: root.tempPath
        onLoaded: root.temperature = Number(text()) / 1000
    }

    // Resolve the CPU hwmon by driver name; hwmonN numbering isn't stable across boots.
    Process {
        running: true
        command: ["sh", "-c", 'for n in "$@"; do for h in /sys/class/hwmon/hwmon*; do [ "$(cat "$h/name")" = "$n" ] && echo "$h/temp1_input" && exit; done; done', "sh", ...Theme.tempSensors]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = text.trim()
        }
    }
}
