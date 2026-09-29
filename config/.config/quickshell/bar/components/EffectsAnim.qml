import QtQuick
import qs.config

NumberAnimation {
    duration: Theme.durationEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curveEffects
}
