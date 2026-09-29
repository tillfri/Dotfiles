import QtQuick
import Quickshell
import qs.config

// One waybar-style module: horizontal padding, hover tooltip or popout, click/right-click/scroll handlers.
MouseArea {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property string tooltip
    // Pane this item opens in the Popouts overlay on hover ("" = none).
    property string popout
    readonly property var popouts: QsWindow.window?.popouts ?? null

    signal leftClicked
    signal rightClicked
    signal scrolledUp
    signal scrolledDown

    property real wheelAccum: 0

    implicitWidth: row.implicitWidth + Theme.modulePadding * 2
    implicitHeight: row.implicitHeight
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: e => {
        if (e.button === Qt.RightButton)
            rightClicked();
        else
            leftClicked();
    }

    // Accumulate so high-resolution touchpad scrolling steps like a mouse wheel notch.
    onWheel: e => {
        wheelAccum += e.angleDelta.y;
        while (wheelAccum >= 120) {
            wheelAccum -= 120;
            scrolledUp();
        }
        while (wheelAccum <= -120) {
            wheelAccum += 120;
            scrolledDown();
        }
    }

    onContainsMouseChanged: {
        if (popout)
            popouts?.setHover(popout, root, containsMouse);
        if (containsMouse)
            tipTimer.restart();
        else {
            tipTimer.stop();
            tip.shown = false;
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 0
    }

    Timer {
        id: tipTimer

        interval: Theme.tooltipDelay
        onTriggered: tip.shown = true
    }

    Tooltip {
        id: tip

        target: root
        text: root.tooltip
    }
}
