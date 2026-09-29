import QtQuick
import Quickshell
import qs.config

// Card shown below `target` while the pointer is on the target or on the card itself.
PopupWindow {
    id: root

    required property MouseArea target
    default property alias content: inner.data
    property bool open
    readonly property bool hovered: target.containsMouse || cardHover.hovered

    function close(): void {
        openTimer.stop();
        closeTimer.stop();
        open = false;
    }

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            if (!open)
                openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }

    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 6
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    visible: open || card.opacity > 0
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Timer {
        id: openTimer

        interval: Theme.popupOpenDelay
        onTriggered: root.open = true
    }

    // Grace period to cross the gap between the bar and the card.
    Timer {
        id: closeTimer

        interval: Theme.popupCloseDelay
        onTriggered: root.open = false
    }

    Rectangle {
        id: card

        width: parent.width
        height: parent.height
        implicitWidth: inner.implicitWidth + Theme.popupPadding * 2
        implicitHeight: inner.implicitHeight + Theme.popupPadding * 2
        color: Theme.popupBg
        radius: Theme.popupRadius
        border.width: 2
        border.color: Theme.tooltipBorder
        opacity: root.open ? 1 : 0
        transform: Translate {
            y: root.open ? 0 : -8

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

        HoverHandler {
            id: cardHover
        }

        Item {
            id: inner

            x: Theme.popupPadding
            y: Theme.popupPadding
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
