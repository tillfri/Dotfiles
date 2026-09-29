import QtQuick
import qs.config

NumberAnimation {
    duration: Theme.animDuration
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.animCurve
}
