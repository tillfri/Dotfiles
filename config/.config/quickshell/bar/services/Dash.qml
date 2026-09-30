pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// The dashboard opened from the keyboard (SUPER+I): pinned on one screen, where it takes the
// keyboard until SUPER+I again, Esc, or a click outside. Hovering the workspaces still opens it,
// without the keys.
Singleton {
    id: root

    // Name of the screen whose dashboard is pinned open; "" when none.
    property string screen

    function open(): void {
        const name = Hypr.focusedScreen?.name ?? "";
        // A focused screen without a bar has no dashboard; use the first one that has.
        screen = Theme.screens[name] !== undefined ? name : Quickshell.screens.find(s => Theme.screens[s.name] !== undefined)?.name ?? "";
    }

    function close(): void {
        screen = "";
    }

    function toggle(): void {
        if (screen !== "")
            close();
        else
            open();
    }

    IpcHandler {
        target: "dashboard"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }
}
