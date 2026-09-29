pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Trimmed from caelestia-shell services/Hypr.qml.
Singleton {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property bool usingLua: Hyprland.usingLua
    readonly property HyprlandWorkspace focusedWorkspace: Hyprland.focusedWorkspace
    readonly property int activeWsId: focusedWorkspace?.id ?? 1
    readonly property HyprlandMonitor focusedMonitor: Hyprland.focusedMonitor
    // Where the OSD and notifications show up, like swayosd's/swaync's --monitor of the focused one.
    readonly property ShellScreen focusedScreen: Quickshell.screens.find(s => s.name === focusedMonitor?.name) ?? Quickshell.screens[0] ?? null

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function focusWorkspace(ws: var): void {
        dispatch(usingLua ? `hl.dsp.focus({ workspace = "${ws}" })` : `workspace ${ws}`);
    }

    function toplevelsForWs(ws: int): list<HyprlandToplevel> {
        return toplevels.values.filter(t => t.workspace && t.workspace.id === ws && !isToplevelIgnored(t));
    }

    function isToplevelIgnored(toplevel: HyprlandToplevel): bool {
        const ipc = toplevel?.lastIpcObject;
        return !ipc?.class || !ipc.mapped;
    }

    Component.onCompleted: {
        Hyprland.refreshToplevels();
        Hyprland.refreshWorkspaces();
    }

    // Quickshell only updates some state from events; refresh the rest (window classes, workspace ids).
    Connections {
        function onRawEvent(event: HyprlandEvent): void {
            const n = event.name;
            if (n.endsWith("v2"))
                return;

            if (["workspace", "moveworkspace", "activespecial", "focusedmon"].includes(n)) {
                Hyprland.refreshWorkspaces();
                Hyprland.refreshMonitors();
            } else if (["openwindow", "closewindow", "movewindow"].includes(n)) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (n.includes("mon")) {
                Hyprland.refreshMonitors();
            } else if (n.includes("workspace")) {
                Hyprland.refreshWorkspaces();
            } else if (n.includes("window") || n.includes("group") || ["pin", "fullscreen", "changefloatingmode", "minimize"].includes(n)) {
                Hyprland.refreshToplevels();
            }
        }

        target: Hyprland
    }
}
