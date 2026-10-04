import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services as S

// Bluetooth (replaces blueman-applet): hover for the card (BluetoothPopup), click to switch the
// adapter on or off. Shows the battery of the first connected device that reports one.
BarModule {
    id: root

    readonly property var battery: S.Bt.connected.find(d => d.batteryAvailable) ?? null
    // SUPER+B pinned the card on this bar's screen.
    readonly property bool pinned: S.Bt.pinnedScreen !== "" && S.Bt.pinnedScreen === QsWindow.window?.screen?.name

    visible: S.Bt.adapter !== null
    popout: "bluetooth"
    onLeftClicked: S.Bt.setPower(!S.Bt.enabled)
    onPinnedChanged: popouts?.pin(pinned ? "bluetooth" : "", root)

    StyledText {
        color: S.Bt.enabled ? Theme.fg : Theme.dim
        text: {
            if (!S.Bt.enabled)
                return "\u{f00b2}";
            if (S.Bt.connected.length === 0)
                return "\u{f00af}";
            return root.battery ? `\u{f00b1} ${Math.round(root.battery.battery * 100)}%` : "\u{f00b1}";
        }
    }
}
