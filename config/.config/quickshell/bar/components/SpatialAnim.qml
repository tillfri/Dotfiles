import QtQuick
import qs.config

NumberAnimation {
    duration: Theme.durationSpatial
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curveSpatial
}
