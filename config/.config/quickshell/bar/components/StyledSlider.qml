import QtQuick
import qs.config

// Horizontal 0..1 slider. `value` is bound from outside; interaction only emits `moved`.
MouseArea {
    id: root

    property real value
    property real step: 0.05
    property bool dimmed
    property real wheelAccum: 0

    signal moved(real value)

    function emit(v: real): void {
        moved(Math.max(0, Math.min(1, v)));
    }

    implicitWidth: 180
    implicitHeight: 20
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    onPressed: e => emit(e.x / width)
    onPositionChanged: e => {
        if (pressed)
            emit(e.x / width);
    }
    onWheel: e => {
        wheelAccum += e.angleDelta.y;
        while (Math.abs(wheelAccum) >= 120) {
            const dir = Math.sign(wheelAccum);
            wheelAccum -= dir * 120;
            emit(value + dir * step);
        }
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: Theme.surfaceHover

        Rectangle {
            width: Math.max(height, track.width * root.value)
            height: parent.height
            radius: parent.radius
            opacity: root.dimmed ? 0.35 : 1

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: Theme.accent
                }
                GradientStop {
                    position: 1
                    color: Theme.accent2
                }
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.value * (root.width - width)
        width: 14
        height: width
        radius: width / 2
        color: root.dimmed ? Theme.dim : Theme.fg
        scale: root.pressed ? 1.2 : root.containsMouse ? 1.1 : 1

        Behavior on scale {
            NumberAnimation {
                duration: 120
            }
        }
    }
}
