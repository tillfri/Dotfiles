pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import qs.components
import qs.config
import qs.services as S

// Hover card for the bluetooth module, laid out like the network card: the adapter with its power
// switch, the paired devices (click to connect or disconnect, right click to forget) and the other
// devices nearby (expanded inline, scanning while open; click one to pair and connect).
Column {
    id: root

    // True while the card is visible.
    property bool shown
    // The other devices are expanded below their row.
    property bool listOpen
    // The adapter scans while this card lists the unpaired devices.
    readonly property bool scanning: shown && listOpen && S.Bt.enabled
    readonly property int rowHeight: 32

    width: Theme.networkCardWidth
    spacing: Theme.popupSpacing

    onShownChanged: {
        if (shown)
            listOpen = false;
    }
    onScanningChanged: S.Bt.scanners += scanning ? 1 : -1
    Component.onDestruction: if (scanning)
        S.Bt.scanners--

    // Hover intent, as in NetworkPopup: the list only expands once the pointer rests on its row.
    Timer {
        id: expandTimer

        interval: 150
        onTriggered: root.listOpen = true
    }

    // Adapter and power switch
    Item {
        width: root.width
        implicitHeight: root.rowHeight

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Label {
                color: S.Bt.enabled ? Theme.accent : Theme.dim
                text: S.Bt.enabled ? "\u{f00af}" : "\u{f00b2}"
            }
            Label {
                text: S.Bt.adapter?.name || "Bluetooth"
            }
        }

        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: S.Bt.enabled ? Theme.accent : Theme.dim
            text: S.Bt.enabled ? "\u{f0521}" : "\u{f0522}"
        }

        Highlight {
            onClicked: S.Bt.setPower(!S.Bt.enabled)
        }
    }

    Separator {
        visible: S.Bt.enabled
    }

    // Paired devices
    Label {
        visible: S.Bt.enabled
        text: S.Bt.paired.length > 0 ? "Paired devices" : "No paired devices"
        color: Theme.dim
    }

    Repeater {
        model: S.Bt.enabled ? S.Bt.paired : []

        DeviceRow {
            width: root.width
        }
    }

    Separator {
        visible: S.Bt.enabled
    }

    // Other devices
    Item {
        visible: S.Bt.enabled
        width: root.width
        implicitHeight: root.rowHeight

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Other devices"
        }

        // Points down while expanded.
        Label {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: root.listOpen ? Theme.accent : Theme.dim
            text: "\u{f0142}"
            rotation: root.listOpen ? 90 : 0

            Behavior on rotation {
                EffectsAnim {}
            }
        }

        Highlight {
            onContainsMouseChanged: {
                if (containsMouse && !root.listOpen)
                    expandTimer.restart();
                else
                    expandTimer.stop();
            }
            onClicked: {
                expandTimer.stop();
                root.listOpen = !root.listOpen;
            }
        }
    }

    Flickable {
        visible: S.Bt.enabled && root.listOpen
        width: root.width
        height: Math.min(contentHeight, root.rowHeight * Theme.networkMaxRows)
        contentHeight: otherList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: otherList

            width: parent.width

            Label {
                x: 16
                visible: S.Bt.unpaired.length === 0
                height: root.rowHeight
                color: Theme.dim
                text: S.Bt.adapter?.discovering ? "Scanning…" : "No devices found"
            }

            Repeater {
                model: S.Bt.unpaired

                DeviceRow {
                    width: otherList.width
                    indent: 16
                }
            }
        }
    }

    component DeviceRow: Item {
        id: device

        required property BluetoothDevice modelData
        property int indent: 0
        readonly property int pct: Math.round(modelData.battery * 100)
        readonly property string status: {
            const d = modelData;
            if (d.pairing || S.Bt.pairing === d)
                return "pairing…";
            if (d.state === BluetoothDeviceState.Connecting)
                return "connecting…";
            if (d.state === BluetoothDeviceState.Disconnecting)
                return "disconnecting…";
            if (d.connected)
                return d.batteryAvailable ? `${pct}%  connected` : "connected";
            return "";
        }

        implicitHeight: root.rowHeight

        Row {
            id: deviceRow

            x: device.indent
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Label {
                color: device.modelData.connected ? Theme.accent : Theme.dim
                text: S.Bt.glyph(device.modelData.icon)
            }
            Label {
                width: Math.min(implicitWidth, device.width - deviceRow.x - statusLabel.width - 40)
                elide: Text.ElideRight
                text: device.modelData.name
            }
        }

        Label {
            id: statusLabel

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            color: device.modelData.connected ? Theme.accent : Theme.dim
            text: device.status
        }

        Highlight {
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            enabled: !device.modelData.pairing && S.Bt.pairing !== device.modelData
            onClicked: e => {
                const d = device.modelData;
                if (e.button === Qt.RightButton) {
                    if (d.paired)
                        d.forget();
                } else if (d.paired) {
                    S.Bt.toggleDevice(d);
                } else {
                    S.Bt.pairAndConnect(d);
                }
            }
        }
    }

    component Separator: Rectangle {
        width: root.width
        height: 1
        color: Theme.surfaceHover
    }

    // Clickable row background that lights up on hover.
    component Highlight: MouseArea {
        id: area

        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: -1

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: area.containsMouse && area.enabled ? Theme.surfaceHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }
    }

    component Label: StyledText {
        font.pixelSize: Theme.popupFontSize
    }
}
