import QtQuick
import qs.config

// caelestia's vertical OSD slider (components/controls/FilledSlider.qml): a pill that fills from the
// bottom, with a round handle on top of the fill showing `icon`, or the percentage for a moment
// after the value changes. Like StyledSlider, `value` is bound from outside and input emits `moved`.
MouseArea {
    id: root

    property real value
    property string icon
    property bool dimmed
    property real step: 0.05
    property real wheelAccum: 0
    // Animated copy of `value` that the visuals follow.
    property real shownValue: value
    property bool moving

    signal moved(real value)

    function emit(v: real): void {
        moved(Math.max(0, Math.min(1, v)));
    }

    function fromY(y: real): real {
        return 1 - (y - width / 2) / (height - width);
    }

    implicitWidth: Theme.osdSliderWidth
    implicitHeight: Theme.osdSliderHeight
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor

    onPressed: e => emit(fromY(e.y))
    onPositionChanged: e => {
        if (pressed)
            emit(fromY(e.y));
    }
    onWheel: e => {
        wheelAccum += e.angleDelta.y;
        while (Math.abs(wheelAccum) >= 120) {
            const dir = Math.sign(wheelAccum);
            wheelAccum -= dir * 120;
            emit(value + dir * step);
        }
    }
    onPressedChanged: {
        moving = true;
        movingTimer.restart();
    }
    onValueChanged: {
        moving = true;
        movingTimer.restart();
    }

    Behavior on shownValue {
        NumberAnimation {
            duration: Theme.durationSpatial
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.curveStandard
        }
    }

    Timer {
        id: movingTimer

        interval: 500
        onTriggered: root.moving = root.pressed
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Theme.surfaceHover

        // Fill: from the bottom up to the handle's top edge.
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: handle.height + (root.height - handle.height) * Math.max(0, Math.min(1, root.shownValue))
            radius: parent.radius
            opacity: root.dimmed ? 0.35 : 1

            Behavior on opacity {
                EffectsAnim {}
            }

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.accent2
                }
                GradientStop {
                    position: 1
                    color: Theme.accent
                }
            }
        }
    }

    Rectangle {
        id: handle

        y: (root.height - height) * (1 - Math.max(0, Math.min(1, root.shownValue)))
        width: root.width
        height: width
        radius: width / 2
        color: Theme.fg
        scale: root.pressed ? 1.08 : 1

        Behavior on scale {
            EffectsAnim {}
        }

        StyledText {
            id: label

            // Swapped mid-animation by the Behavior below.
            property bool showNumber: root.moving

            anchors.centerIn: parent
            anchors.horizontalCenterOffset: showNumber ? 0 : -1
            font.pixelSize: showNumber ? 11 : 15
            color: Theme.wsFg
            text: showNumber ? Math.round(root.value * 100) : root.icon

            // caelestia's pop: shrink, swap, grow back.
            Behavior on showNumber {
                SequentialAnimation {
                    NumberAnimation {
                        target: label
                        property: "scale"
                        to: 0.3
                        duration: 60
                        easing.type: Easing.InCubic
                    }
                    PropertyAction {}
                    NumberAnimation {
                        target: label
                        property: "scale"
                        to: 1
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
