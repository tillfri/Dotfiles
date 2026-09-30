import QtQuick
import Quickshell.Services.UPower
import qs.components
import qs.config

BarModule {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)
    readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(dev?.state)
    readonly property bool critical: percent <= 20 && !charging
    readonly property list<string> icons: ["\u{f008e}", "\u{f007a}", "\u{f007b}", "\u{f007c}", "\u{f007d}", "\u{f007e}", "\u{f007f}", "\u{f0080}", "\u{f0081}", "\u{f0082}", "\u{f0079}"]
    // waybar `blink` keyframes: 1.5s linear, alternate
    property real phase

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    // Only real laptop batteries; peripherals like the mouse also show up in UPower.
    visible: dev?.isLaptopBattery ?? false

    SequentialAnimation on phase {
        running: root.critical && root.visible
        loops: Animation.Infinite

        NumberAnimation {
            from: 0
            to: 1
            duration: 1500
        }
        NumberAnimation {
            from: 1
            to: 0
            duration: 1500
        }
    }

    // Only as tall as the text: on the thinkpad the bar's bottom overlaps windows (exclusiveOffset).
    Rectangle {
        parent: root
        z: -1
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.implicitHeight
        visible: root.critical
        color: root.mix("#f53c3c", "#ffffff", root.phase)
    }

    StyledText {
        text: `${root.charging ? "" : root.icons[Math.min(10, Math.floor(root.percent / 10))]} ${root.percent}%`
        color: root.critical ? root.mix("#ffffff", "#000000", root.phase) : Theme.fg
    }
}
