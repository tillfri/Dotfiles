pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: `${Quickshell.env("HOME")}/.config/hypr/scripts/update-sys`
    property string text

    function check(): void {
        checkProc.running = true;
    }

    function update(): void {
        updateProc.running = true;
    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 15 * 60 * 1000
        onTriggered: root.check()
    }

    Process {
        id: checkProc

        command: [root.script]
        stdout: StdioCollector {
            onStreamFinished: root.text = text.trim()
        }
    }

    // Blocks until the kitty window running `yay -Syu` closes, then re-checks.
    Process {
        id: updateProc

        command: [root.script, "update"]
        onExited: root.check()
    }
}
