pragma Singleton

import QtQuick
import Quickshell

// Values ported from ~/.config/waybar/{style.css,desktop.jsonc,thinkpad.jsonc}
Singleton {
    // Screens that get a bar. Waybar's `height` was only a minimum; the 18px font made the
    // desktop bar 43px tall, so use that. `exclusiveOffset` mirrors thinkpad's margin-bottom: -10.
    readonly property var screens: ({
            "DP-2": {
                height: 43,
                exclusiveOffset: 0
            },
            "eDP-1": {
                height: 36,
                exclusiveOffset: -10
            }
        })
    readonly property int marginH: 10
    readonly property int marginTop: 2

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 18
    readonly property color fg: "#f6f7fc"
    readonly property color critical: "#e92d4d"

    readonly property int modulePadding: 8
    readonly property int moduleMargin: 3

    readonly property color tooltipBg: "#1e1e2e"
    readonly property color tooltipBorder: "#11111b"
    readonly property color tooltipFg: "#cdd6f4"
    readonly property real tooltipOpacity: 0.8
    readonly property int tooltipDelay: 400

    readonly property color wsContainerBg: Qt.rgba(21 / 255, 18 / 255, 27 / 255, 0.49)
    readonly property color wsFg: "#0F1419"
    // Inactive: linear-gradient(#95E6CB, #59C2FF, #D2A6FF); hover/active: linear-gradient(#59C2FF, #D2A6FF).
    // Both use three stops (active middle = midpoint) so the colours can animate between them.
    readonly property list<color> wsGradient: ["#95E6CB", "#59C2FF", "#D2A6FF"]
    readonly property list<color> wsGradientActive: ["#59C2FF", "#95B4FF", "#D2A6FF"]
    readonly property int wsPersistent: 5
    readonly property int wsMinActiveWidth: 40

    // transition: all 0.2s cubic-bezier(.55,-0.68,.48,1.682)
    readonly property int animDuration: 200
    readonly property list<real> animCurve: [0.55, -0.68, 0.48, 1.682, 1, 1]

    // waybar's icon-size is 16, but GTK rendered the tray icons at ~22px
    readonly property int trayIconSize: 22
    readonly property int traySpacing: 10

    // Hover popups and the dashboard: tooltip look, but only the background is translucent.
    readonly property color popupBg: Qt.rgba(30 / 255, 30 / 255, 46 / 255, 0.9)
    readonly property int popupRadius: 10
    readonly property int popupPadding: 12
    readonly property int popupSpacing: 8
    readonly property int popupOpenDelay: 150
    readonly property int popupCloseDelay: 250
    // Longer so passing over the workspaces on the way to a click doesn't flash the dashboard.
    readonly property int dashOpenDelay: 350
    readonly property int popupAnimDuration: 180
    readonly property int popupFontSize: 15
    readonly property color accent: "#59C2FF"
    readonly property color accent2: "#D2A6FF"
    readonly property color dim: "#7f849c"
    readonly property color surface: Qt.rgba(1, 1, 1, 0.06)
    readonly property color surfaceHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property int dashRadius: 15

    readonly property int stateInterval: 5000
    readonly property int tempCritical: 80
    readonly property list<string> tempSensors: ["k10temp", "coretemp"]
}
