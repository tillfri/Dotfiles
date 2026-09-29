import QtQuick
import qs.components
import qs.config
import qs.services

MouseArea {
    id: root

    required property int modelData
    readonly property bool active: Hypr.activeWsId === modelData
    readonly property string windows: Hypr.toplevelsForWs(modelData).map(t => WindowIcons.iconFor(t.lastIpcObject.class, t.title)).join(" ")
    readonly property list<color> stops: active || containsMouse ? Theme.wsGradientActive : Theme.wsGradient

    implicitWidth: pill.width + 6
    hoverEnabled: true
    onClicked: Hypr.focusWorkspace(modelData)

    Rectangle {
        id: pill

        anchors.centerIn: parent
        height: parent.height - 8
        // Never narrower than tall, so empty workspaces are circles like in waybar.
        width: Math.max(label.implicitWidth + 10, height, root.active ? Theme.wsMinActiveWidth : 0)
        radius: 15
        opacity: root.active ? 1 : root.containsMouse ? 0.8 : 0.5

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: root.stops[0]

                Behavior on color {
                    CAnim {}
                }
            }
            GradientStop {
                position: 0.5
                color: root.stops[1]

                Behavior on color {
                    CAnim {}
                }
            }
            GradientStop {
                position: 1
                color: root.stops[2]

                Behavior on color {
                    CAnim {}
                }
            }
        }

        StyledText {
            id: label

            anchors.centerIn: parent
            color: Theme.wsFg
            text: root.windows
        }

        Behavior on width {
            Anim {}
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
