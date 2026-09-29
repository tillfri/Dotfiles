import QtQuick
import qs.config

// Nerd Font glyph with a round hover highlight.
MouseArea {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property int padding: 6

    implicitWidth: Math.max(label.implicitWidth, label.implicitHeight) + padding * 2
    implicitHeight: label.implicitHeight + padding * 2
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    opacity: enabled ? 1 : 0.35

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.containsMouse && root.enabled ? Theme.surfaceHover : "transparent"
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        font.pixelSize: Theme.popupFontSize
    }
}
