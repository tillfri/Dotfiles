import QtQuick
import qs.config

ColorAnimation {
    duration: Theme.animDuration
    easing.type: Easing.Bezier
    easing.bezierCurve: Theme.animCurve
}
