pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// swaync's control center (SUPER+N): "Notifications" header with clear-all, the Do-not-disturb
// switch, and the notifications grouped by app. Slides in from the right edge of the focused
// screen; a click outside, Esc, or SUPER+N again closes it. Keys: D toggles DND, C clears all.
PanelWindow {
    id: root

    // caelestia's offsetScale: 0 = open, 1 = past the right edge.
    property real offsetScale: Notifs.centerOpen ? 0 : 1
    // Newest group first, in the order of each app's latest notification.
    readonly property var groups: [...new Set(Notifs.list.map(n => n.appName))]

    screen: Hypr.focusedScreen
    anchors {
        top: true
        right: true
    }
    margins {
        top: 2
        right: 1
    }
    implicitWidth: Theme.notifCenterWidth
    implicitHeight: Math.min(Theme.notifCenterHeight, (screen?.height ?? 1000) - 60)
    color: "transparent"
    visible: Notifs.centerOpen || offsetScale < 1
    WlrLayershell.namespace: "quickshell-notifcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Notifs.centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: panel
    }

    Behavior on offsetScale {
        SpatialAnim {}
    }

    HyprlandFocusGrab {
        windows: [root]
        active: Notifs.centerOpen
        onCleared: Notifs.setCenterOpen(false)
    }

    Rectangle {
        id: panel

        // .control-center { margin: 18px; padding: 12px }
        x: 18 + (root.width) * root.offsetScale
        y: 18
        width: root.width - 36
        height: root.height - 36
        color: Theme.notifBg
        radius: Theme.notifRadius
        border.width: 1
        border.color: Theme.notifCenterBorder
        opacity: 1 - root.offsetScale
        focus: true

        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape)
                Notifs.setCenterOpen(false);
            else if (e.key === Qt.Key_D)
                Notifs.dnd = !Notifs.dnd;
            else if (e.key === Qt.Key_C)
                Notifs.clearAll();
            else
                return;
            e.accepted = true;
        }

        Column {
            id: top

            x: 12
            y: 12
            width: parent.width - 24
            spacing: 6

            // Header: "Notifications" + clear-all.
            Item {
                width: parent.width
                height: 40

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6
                    font.pixelSize: 22
                    text: "Notifications"
                }

                PlainButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: " \u{f039f} "
                    enabled: Notifs.list.length > 0
                    onClicked: Notifs.clearAll()
                }
            }

            // Do not disturb.
            Item {
                width: parent.width
                height: 40

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 6
                    font.pixelSize: 20
                    text: "Do not disturb"
                }

                Switch {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Notifs.dnd
                    onToggled: Notifs.dnd = !Notifs.dnd
                }
            }
        }

        Flickable {
            id: flick

            anchors.top: top.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            x: 12
            width: parent.width - 24
            contentHeight: groupsColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groupsColumn

                width: flick.width
                spacing: 16

                Repeater {
                    model: ScriptModel {
                        values: root.groups
                    }

                    Group {}
                }
            }
        }

        // Empty state.
        Column {
            anchors.centerIn: flick
            spacing: 8
            opacity: Notifs.list.length === 0 ? 1 : 0

            Behavior on opacity {
                EffectsAnim {}
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 48
                color: Theme.dim
                text: "\u{f009b}"
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.notifBodySize
                color: Theme.dim
                text: "No notifications"
            }
        }
    }

    // One app's notifications. With several, a header (icon, name, count, expand, close-all);
    // collapsed shows only the newest.
    component Group: Column {
        id: group

        required property string modelData
        readonly property var entries: Notifs.list.filter(n => n.appName === modelData)
        property bool expanded

        width: groupsColumn.width
        spacing: 6

        Item {
            visible: group.entries.length > 1
            width: parent.width
            height: 34

            IconImage {
                id: groupIcon

                readonly property string icon: group.entries[0]?.appIcon ?? ""

                anchors.verticalCenter: parent.verticalCenter
                x: 4
                implicitSize: 20
                visible: icon !== "" && !icon.includes("/")
                source: visible ? Quickshell.iconPath(icon, true) : ""
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: groupIcon.visible ? groupIcon.right : parent.left
                anchors.leftMargin: groupIcon.visible ? 8 : 4
                anchors.right: groupButtons.left
                elide: Text.ElideRight
                font.pixelSize: 20
                font.letterSpacing: 2
                text: `${group.modelData || "Unknown"}  ${group.entries.length}`
            }

            Row {
                id: groupButtons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                PlainButton {
                    text: group.expanded ? "\u{f0143}" : "\u{f0140}"
                    onClicked: group.expanded = !group.expanded
                }
                PlainButton {
                    text: "\u{f0156}"
                    onClicked: {
                        for (const e of group.entries)
                            Notifs.dismiss(e);
                    }
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: group.entries
            }

            // Collapsible slot: the height animates so expanding/closing moves the rest smoothly.
            Item {
                id: slot

                required property var modelData
                required property int index
                readonly property bool shown: (group.expanded || index === 0) && !modelData.leaving
                // Collapsed group: a thin edge under the newest card hints at the stack.
                readonly property bool stacked: index === 0 && !group.expanded && group.entries.length > 1

                width: group.width
                height: shown ? card.implicitHeight + (stacked ? 8 : 0) : 0
                visible: height > 0
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.durationSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.curveStandard
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: card.implicitHeight + 2
                    width: slot.width - 40
                    height: 6
                    radius: 3
                    color: Theme.surfaceHover
                    opacity: slot.stacked ? 1 : 0

                    Behavior on opacity {
                        EffectsAnim {}
                    }
                }

                NotificationCard {
                    id: card

                    width: slot.width
                    center: true
                    entry: slot.modelData
                }
            }
        }
    }

    // swaync's .widget-title button / group buttons: flat, rounded, light hover.
    component PlainButton: MouseArea {
        id: button

        property alias text: label.text

        implicitWidth: Math.max(34, label.implicitWidth + 16)
        implicitHeight: 34
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        opacity: enabled ? 1 : 0.4

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: button.containsMouse && button.enabled ? Qt.rgba(1, 1, 1, 0.4) : Theme.notifRow

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            font.pixelSize: 18
        }
    }

    // .widget-dnd > switch: rounded track, light when checked, sliding knob.
    component Switch: MouseArea {
        id: sw

        property bool checked

        signal toggled

        implicitWidth: 52
        implicitHeight: 28
        cursorShape: Qt.PointingHandCursor
        onClicked: toggled()

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: sw.checked ? Theme.notifCenterBorder : Theme.notifRow
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.15)

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }

        Rectangle {
            x: sw.checked ? sw.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: sw.height - 6
            height: width
            radius: 6
            color: sw.checked ? Theme.notifButton : Theme.fg

            Behavior on x {
                SpatialAnim {}
            }
        }
    }
}
