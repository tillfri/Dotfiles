pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.config
import qs.services

// BlueZ state for the bluetooth module and card (modules/Bluetooth*.qml), replacing blueman.
// (Not called Bluetooth, which would shadow Quickshell's singleton.) Opened from the keyboard
// with SUPER+B over IPC: the card is then pinned under the module on one screen, like the dashboard.
// There is no pairing agent: devices that ask for a PIN or passkey still need bluetoothctl.
Singleton {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false
    // Connected first, then paired, then by name; unpaired devices without a name are left out.
    readonly property list<BluetoothDevice> devices: [...(adapter?.devices.values ?? [])].filter(d => d.paired || d.deviceName !== "").sort((a, b) => b.connected - a.connected || b.paired - a.paired || a.name.localeCompare(b.name))
    readonly property list<BluetoothDevice> paired: devices.filter(d => d.paired)
    readonly property list<BluetoothDevice> unpaired: devices.filter(d => !d.paired)
    readonly property list<BluetoothDevice> connected: devices.filter(d => d.connected)
    // Number of open cards that list the unpaired devices; the adapter scans while there are any.
    property int scanners: 0
    // Name of the screen whose card is pinned open; "" when none.
    property string pinnedScreen
    // Being paired from the card; trusted and connected once pairing is through.
    property BluetoothDevice pairing: null

    // Nerd Font glyph for a BlueZ device icon name.
    function glyph(icon: string): string {
        if (icon.startsWith("audio-head"))
            return "\u{f02cb}";
        if (icon.startsWith("audio"))
            return "\u{f04c3}";
        if (icon === "input-mouse")
            return "\u{f037d}";
        if (icon === "input-keyboard")
            return "\u{f030c}";
        if (icon === "input-gaming")
            return "\u{f0297}";
        if (icon === "phone")
            return "\u{f011c}";
        if (icon === "computer")
            return "\u{f0322}";
        return "\u{f00af}";
    }

    function setPower(on: bool): void {
        if (adapter)
            adapter.enabled = on;
    }

    function toggleDevice(d: BluetoothDevice): void {
        if (d.connected)
            d.disconnect();
        else
            d.connect();
    }

    function pairAndConnect(d: BluetoothDevice): void {
        pairing = d;
        d.pair();
    }

    function open(): void {
        const name = Hypr.focusedScreen?.name ?? "";
        // As in Dash: a focused screen without a bar has no module to open under.
        pinnedScreen = Theme.screens[name] !== undefined ? name : Quickshell.screens.find(s => Theme.screens[s.name] !== undefined)?.name ?? "";
        Dash.close();
    }

    function close(): void {
        pinnedScreen = "";
    }

    onScannersChanged: {
        if (adapter?.enabled)
            adapter.discovering = scanners > 0;
    }

    Connections {
        target: root.pairing

        function onPairedChanged(): void {
            const d = root.pairing;
            if (!d.paired)
                return;
            root.pairing = null;
            d.trusted = true;
            d.connect();
        }

        // Pairing ended without success (refused, timed out or cancelled).
        function onPairingChanged(): void {
            if (!root.pairing.pairing && !root.pairing.paired)
                root.pairing = null;
        }
    }

    IpcHandler {
        target: "bluetooth"

        function toggle(): void {
            if (root.pinnedScreen !== "")
                root.close();
            else
                root.open();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function power(): void {
            root.setPower(!root.enabled);
        }
    }
}
