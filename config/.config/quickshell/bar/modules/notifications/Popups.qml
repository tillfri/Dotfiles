import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Floating notifications (swaync's notification window): top right of the focused screen, below
// the bar, newest on top. Cards slide in from the right edge and out again when they expire.
PanelWindow {
    id: root

    screen: Hypr.focusedScreen
    anchors {
        top: true
        right: true
    }
    margins.top: Theme.marginTop
    implicitWidth: Theme.notifWidth
    // A layer surface can't be 0 tall.
    implicitHeight: Math.max(1, Math.min(list.contentHeight + Theme.notifMargin, (screen?.height ?? 1000) - 100))
    color: "transparent"
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    visible: !Notifs.centerOpen

    mask: Region {
        item: list.contentItem
    }

    ListView {
        id: list

        anchors.fill: parent
        anchors.leftMargin: Theme.notifMargin
        anchors.rightMargin: Theme.notifMargin
        anchors.topMargin: Theme.notifMargin
        spacing: Theme.notifMargin
        interactive: false

        model: ScriptModel {
            values: [...Notifs.popups]
        }

        delegate: NotificationCard {
            required property var modelData

            width: list.width
            entry: modelData
        }

        add: Transition {
            SpatialAnim {
                property: "x"
                from: Theme.notifWidth
                to: 0
            }
            EffectsAnim {
                property: "opacity"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            SpatialAnim {
                property: "x"
                to: Theme.notifWidth
            }
            EffectsAnim {
                property: "opacity"
                to: 0
            }
        }

        // Also finishes an add transition that a removal interrupted (else the card stays faded).
        displaced: Transition {
            SpatialAnim {
                property: "y"
            }
            SpatialAnim {
                property: "x"
                to: 0
            }
            EffectsAnim {
                property: "opacity"
                to: 1
            }
        }
    }
}
