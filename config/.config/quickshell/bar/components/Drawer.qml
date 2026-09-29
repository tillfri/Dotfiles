import QtQuick
import qs.config

// A caelestia-style drawer in the Popouts overlay. The card grows out from under the bar below the
// hovered target, glides and resizes when the target changes while open, and closes a moment after
// the pointer has left both the target and the card. The item itself is the visible (clipped) area,
// so it doubles as the overlay's input mask.
Item {
    id: root

    property int openDelay: Theme.popupOpenDelay
    property alias radius: card.radius
    // Size of the current content; defaults to everything inside the card.
    property real contentWidth: inner.childrenRect.width
    property real contentHeight: inner.childrenRect.height
    default property alias content: inner.data

    property bool open
    // What is shown (kept while closing so the content doesn't vanish mid-animation).
    property string current
    property Item currentItem
    // What the pointer is on right now.
    property string hoveredName
    property Item hoveredItem
    readonly property bool cardHovered: cardHover.hovered

    // caelestia's offsetScale: 0 = open, 1 = tucked under the bar.
    property real offsetScale: open ? 0 : 1
    readonly property real fullHeight: card.implicitHeight + Theme.popupGap
    readonly property real targetCenter: {
        if (!currentItem)
            return 0;
        return currentItem.mapToItem(null, currentItem.width / 2, 0).x;
    }

    function setHover(name: string, item: Item, hovered: bool): void {
        if (hovered) {
            hoveredName = name;
            hoveredItem = item;
        } else if (hoveredName === name && hoveredItem === item) {
            hoveredName = "";
        }
        update();
    }

    function close(): void {
        openTimer.stop();
        closeTimer.stop();
        open = false;
    }

    function show(): void {
        // Target first, then open: the position only animates while already (partly) open.
        current = hoveredName;
        currentItem = hoveredItem;
        open = true;
    }

    function update(): void {
        if (hoveredName !== "") {
            closeTimer.stop();
            if (open)
                show();
            else
                openTimer.restart();
        } else if (cardHover.hovered) {
            closeTimer.stop();
        } else {
            openTimer.stop();
            if (open)
                closeTimer.restart();
        }
    }

    // Uses the final (implicit) width: binding to the animated width would restart the x animation
    // every frame while the card resizes, freezing it until the resize ends.
    x: Math.max(0, Math.min(parent.width - card.implicitWidth, targetCenter - card.implicitWidth / 2))
    width: card.width
    height: (card.height + Theme.popupGap) * (1 - offsetScale)
    // Stays visible at zero height so layouts inside keep their real size for the next open.
    clip: true

    Behavior on offsetScale {
        SpatialAnim {}
    }

    Behavior on x {
        enabled: root.offsetScale < 1

        SpatialAnim {}
    }

    Timer {
        id: openTimer

        interval: root.openDelay
        onTriggered: {
            if (root.hoveredName !== "")
                root.show();
        }
    }

    // Grace period to cross the gap between the bar and the card.
    Timer {
        id: closeTimer

        interval: Theme.popupCloseDelay
        onTriggered: root.open = false
    }

    Rectangle {
        id: card

        anchors.bottom: parent.bottom
        width: implicitWidth
        height: implicitHeight
        implicitWidth: root.contentWidth + Theme.popupPadding * 2
        implicitHeight: root.contentHeight + Theme.popupPadding * 2
        color: Theme.popupBg
        radius: Theme.popupRadius
        border.width: 2
        border.color: Theme.tooltipBorder
        opacity: 1 - root.offsetScale
        clip: true

        Behavior on width {
            enabled: root.offsetScale < 1

            SpatialAnim {}
        }

        Behavior on height {
            enabled: root.offsetScale < 1

            SpatialAnim {}
        }

        HoverHandler {
            id: cardHover

            onHoveredChanged: root.update()
        }

        Item {
            id: inner

            x: Theme.popupPadding
            y: Theme.popupPadding
            width: root.contentWidth
            height: root.contentHeight
        }
    }
}
