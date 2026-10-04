import QtQuick
import qs.components
import qs.config
import qs.services

// Pomodoro timer (services/Focus.qml) under the dashboard clock: click starts, pauses or resumes,
// right click stops, scrolling while stopped sets the work length.
MouseArea {
    id: root

    readonly property int secs: Math.ceil(Focus.remaining / 1000)
    readonly property string clock: `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, "0")}`
    property real wheelAccum: 0

    implicitWidth: content.implicitWidth + 16
    implicitHeight: content.implicitHeight + 8
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor

    onClicked: e => {
        if (e.button === Qt.RightButton)
            Focus.stop();
        else
            Focus.toggle();
    }

    // Accumulate so high-resolution touchpad scrolling steps like a mouse wheel notch.
    onWheel: e => {
        wheelAccum += e.angleDelta.y;
        while (Math.abs(wheelAccum) >= 120) {
            const dir = Math.sign(wheelAccum);
            wheelAccum -= dir * 120;
            Focus.adjust(dir * 5);
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.popupRadius
        color: root.containsMouse ? Theme.surfaceHover : "transparent"
    }

    Column {
        id: content

        anchors.centerIn: parent
        spacing: 2

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.popupFontSize
            color: !Focus.active ? Theme.fg : Focus.paused ? Theme.dim : Focus.phase === "work" ? Theme.accent : Theme.accent2
            text: {
                if (!Focus.active)
                    return `\u{f051b} ${Focus.workMinutes} min`;
                const icon = Focus.paused ? "\u{f03e4}" : Focus.phase === "work" ? "\u{f051b}" : "\u{f0176}";
                return `${icon} ${root.clock}`;
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 12
            font.bold: false
            color: Theme.dim
            text: {
                if (!Focus.active)
                    return `Today: ${Focus.today}`;
                const name = Focus.phase === "work" ? "Focus" : Focus.phase === "short" ? "Break" : "Long break";
                return `${name} ${Focus.cycle}/${Theme.focusCycles}${Focus.paused ? " (paused)" : ""}`;
            }
        }
    }
}
