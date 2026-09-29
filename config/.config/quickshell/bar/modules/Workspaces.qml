import QtQuick
import Quickshell
import qs.config
import qs.modules.dashboard
import qs.services

// waybar hyprland/workspaces: persistent 1-5 plus any other normal workspace, on all outputs.
Rectangle {
    id: root

    readonly property list<int> ids: {
        const set = new Set(Array.from({
            length: Theme.wsPersistent
        }, (_, i) => i + 1));
        for (const ws of Hypr.workspaces.values)
            if (ws.id > 0)
                set.add(ws.id);
        return [...set].sort((a, b) => a - b);
    }

    implicitWidth: row.implicitWidth + 2
    implicitHeight: parent.height - 10
    radius: 15
    color: Theme.wsContainerBg

    Row {
        id: row

        anchors.centerIn: parent

        Repeater {
            model: root.ids

            Workspace {
                height: root.height
            }
        }
    }

    HoverHandler {
        id: hover
    }

    Dashboard {
        target: root
        targetHovered: hover.hovered
    }
}
