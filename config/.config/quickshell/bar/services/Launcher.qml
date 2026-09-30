pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// State of the launcher (modules/launcher): which mode it shows and on which screen. Opened by
// the hyprland binds over IPC; `menu` serves scripts through ~/.config/hypr/scripts/qs-dmenu.
Singleton {
    id: root

    property bool open
    // Frozen while open, so moving the pointer to another monitor doesn't drag the card along.
    property ShellScreen screen
    // "apps" (with the "=" calculator and ":" emoji prefixes), "clipboard" or "menu".
    property string mode: "apps"
    // Counts shows: the content resets on every change, also when reopened mid close animation.
    property int session
    property string initialQuery
    property string menuPrompt
    property list<string> menuItems
    // FIFO the waiting qs-dmenu reads its answer from; "" when no menu is pending.
    property string menuReply
    // Line picked in the menu, reported by settle().
    property string menuChoice

    function show(mode: string, query: string): void {
        settle();
        root.mode = mode;
        initialQuery = query;
        screen = Hypr.focusedScreen;
        session++;
        open = true;
    }

    function close(): void {
        open = false;
        // A pick is reported once the card is off the screen (Spotlight.qml); a dismissal right away.
        if (menuChoice === "")
            settle();
    }

    function toggle(mode: string): void {
        if (open && root.mode === mode)
            close();
        else
            show(mode, "");
    }

    function pick(choice: string): void {
        menuChoice = choice;
        close();
    }

    // Tells the waiting qs-dmenu how its menu ended: the picked line, or an empty one when it
    // was dismissed. The timeout covers a reader that is gone.
    function settle(): void {
        if (menuReply !== "")
            Quickshell.execDetached(["timeout", "2", "sh", "-c", 'printf "%s\\n" "$1" > "$2"', "sh", menuChoice, menuReply]);
        menuReply = "";
        menuChoice = "";
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle("apps");
        }

        function open(): void {
            root.show("apps", "");
        }

        function close(): void {
            root.close();
        }

        // "apps" or "clipboard"; switches when the launcher is open in another mode.
        function toggleMode(mode: string): void {
            if (["apps", "clipboard"].includes(mode))
                root.toggle(mode);
        }

        // Opens the app search with the text already typed, e.g. ":" for the emoji picker.
        function openQuery(query: string): void {
            root.show("apps", query);
        }

        // The open mode, or "closed".
        function current(): string {
            return root.open ? root.mode : "closed";
        }

        // dmenu: `items` are newline separated, the picked line is written to the `reply` FIFO.
        function menu(prompt: string, items: string, reply: string): void {
            root.show("menu", "");
            root.menuPrompt = prompt;
            root.menuItems = [...new Set(items.split("\n").filter(l => l !== ""))];
            root.menuReply = reply;
        }
    }
}
