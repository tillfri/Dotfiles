import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config

// Dropdown under the clock: date/time, calendar, media. Closes on outside click or Escape.
PopupWindow {
    id: root

    required property Item target
    property bool open

    onOpenChanged: {
        if (open)
            calendar.reset();
    }

    // Right edge flush with the bar's right edge, dropping down and to the left.
    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: target.width + Theme.moduleMargin
    anchor.rect.height: target.height + 6
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide

    visible: open || card.opacity > 0
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    // The bar is part of the grab, so clicking the clock again toggles instead of reopening.
    HyprlandFocusGrab {
        active: root.open && root.visible
        windows: [root, root.target.QsWindow.window]
        onCleared: root.open = false
    }

    Rectangle {
        id: card

        width: parent.width
        height: parent.height
        implicitWidth: layout.implicitWidth + Theme.popupPadding * 2
        implicitHeight: layout.implicitHeight + Theme.popupPadding * 2
        color: Theme.popupBg
        radius: Theme.dashRadius
        border.width: 2
        border.color: Theme.tooltipBorder
        opacity: root.open ? 1 : 0
        focus: root.open
        Keys.onEscapePressed: root.open = false
        transform: Translate {
            y: root.open ? 0 : -12

            Behavior on y {
                NumberAnimation {
                    duration: Theme.popupAnimDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.popupAnimDuration
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: layout

            x: Theme.popupPadding
            y: Theme.popupPadding
            spacing: Theme.popupSpacing

            DateTimeCard {
                Layout.fillHeight: true
            }
            CalendarCard {
                id: calendar

                Layout.fillHeight: true
            }
            MediaCard {
                Layout.fillHeight: true
            }
        }
    }
}
