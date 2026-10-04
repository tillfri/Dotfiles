pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// State of the session menu (modules/session), replacing wlogout: opened by SUPER+ESC over IPC.
// The actions are ~/.config/wlogout/layout (three per row): logout, shutdown and reboot on top.
Singleton {
    id: root

    property bool open
    // Frozen while open, so moving the pointer to another monitor doesn't drag the menu along.
    property ShellScreen screen
    // Action picked in the menu, run by settle() once the menu is off the screen.
    property var pending: null

    readonly property list<var> actions: [
        {
            label: "logout",
            text: "Logout",
            key: Qt.Key_E,
            run: () => Hypr.dispatch(Hypr.usingLua ? "hl.dsp.exit()" : "exit")
        },
        {
            label: "shutdown",
            text: "Shutdown",
            key: Qt.Key_S,
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        },
        {
            label: "reboot",
            text: "Reboot",
            key: Qt.Key_R,
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            label: "suspend",
            text: "Suspend",
            key: Qt.Key_U,
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            label: "lock",
            text: "Lock",
            key: Qt.Key_L,
            run: () => Lock.lock()
        },
        {
            label: "hibernate",
            text: "Hibernate",
            key: Qt.Key_H,
            run: () => Quickshell.execDetached(["systemctl", "hibernate"])
        }
    ]

    function show(): void {
        pending = null;
        screen = Hypr.focusedScreen;
        open = true;
    }

    function close(): void {
        open = false;
    }

    function toggle(): void {
        if (open)
            close();
        else
            show();
    }

    function pick(action: var): void {
        pending = action;
        close();
    }

    // Runs the picked action; the lock screen would otherwise catch the menu fading out.
    function settle(): void {
        const action = pending;
        pending = null;
        action?.run();
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.show();
        }

        function close(): void {
            root.close();
        }
    }
}
