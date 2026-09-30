pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.config
import qs.services as S

// Hover card for the nm-applet tray icon, top to bottom: the current network, the available wifi
// networks (expanded inline like a tray submenu; click one to connect), the saved VPNs (click to
// toggle) and the connection's details.
Column {
    id: root

    // True while the card is visible.
    property bool shown
    // The available networks are expanded below their row.
    property bool listOpen
    readonly property int rowHeight: 32

    width: Theme.networkCardWidth
    spacing: Theme.popupSpacing

    onShownChanged: {
        if (shown)
            listOpen = false;
    }
    onListOpenChanged: {
        if (listOpen)
            S.Network.refreshNetworks(true);
    }

    // Rescans while expanded (NetworkManager only really scans if its last scan is older than 30s).
    Timer {
        running: root.shown && root.listOpen
        repeat: true
        interval: 10000
        onTriggered: S.Network.refreshNetworks(true)
    }

    // Hover intent, as in TrayMenu: the list only expands once the pointer rests on its row.
    Timer {
        id: expandTimer

        interval: 150
        onTriggered: root.listOpen = true
    }

    // Current network
    Row {
        spacing: 10

        Label {
            id: currentIcon

            color: S.Network.connected ? Theme.accent : Theme.dim
            text: !S.Network.connected ? "\u{f05aa}" : S.Network.wifi ? S.Network.signalGlyph(S.Network.strength) : "\u{f0200}"
        }
        Label {
            width: root.width - currentIcon.width - 10
            elide: Text.ElideRight
            text: S.Network.connected ? S.Network.name || S.Network.iface : "Disconnected"
        }
    }

    Separator {}

    // Available networks
    Item {
        width: root.width
        implicitHeight: root.rowHeight

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: "Available networks"
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
        visible: root.listOpen
        width: root.width
        height: Math.min(contentHeight, root.rowHeight * Theme.networkMaxRows)
        contentHeight: networkList.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Column {
            id: networkList

            width: parent.width

            Label {
                x: 16
                visible: S.Network.networks.length === 0
                height: root.rowHeight
                color: Theme.dim
                text: S.Network.scanning ? "Scanning…" : "No networks found"
            }

            Repeater {
                model: S.Network.networks

                Item {
                    id: network

                    required property var modelData
                    readonly property bool busy: S.Network.connecting === modelData.ssid
                    readonly property bool failed: S.Network.failed === modelData.ssid

                    width: networkList.width
                    implicitHeight: root.rowHeight

                    Row {
                        id: networkRow

                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Label {
                            color: network.modelData.active ? Theme.accent : Theme.dim
                            text: S.Network.signalGlyph(network.modelData.signal)
                        }
                        Label {
                            width: Math.min(implicitWidth, network.width - networkRow.x - status.width - 70)
                            elide: Text.ElideRight
                            text: network.modelData.ssid
                        }
                        Label {
                            visible: network.modelData.secure
                            color: Theme.dim
                            text: "\u{f033e}"
                        }
                    }

                    Label {
                        id: status

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: network.failed ? Theme.critical : network.modelData.active ? Theme.accent : Theme.dim
                        text: network.busy ? "connecting…" : network.failed ? "failed" : network.modelData.active ? "connected" : ""
                    }

                    Highlight {
                        enabled: !network.modelData.active && S.Network.connecting === ""
                        onClicked: S.Network.connectWifi(network.modelData.ssid)
                    }
                }
            }
        }
    }

    Separator {}

    // VPN connections
    Label {
        text: "VPN Connections"
        color: Theme.dim
    }

    Label {
        visible: S.Network.vpns.length === 0
        text: "No saved VPNs"
        color: Theme.dim
    }

    Repeater {
        model: S.Network.vpns

        Item {
            id: vpn

            required property var modelData
            readonly property bool active: modelData.state === "activated"
            readonly property bool busy: modelData.state === "activating" || modelData.state === "deactivating"

            width: root.width
            implicitHeight: root.rowHeight

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Label {
                    text: vpn.active ? "\u{f033e}" : "\u{f0fc6}"
                    color: vpn.active ? Theme.accent : Theme.dim
                }
                Label {
                    text: vpn.modelData.name
                }
            }

            Label {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: vpn.busy ? `${vpn.modelData.state === "activating" ? "connecting" : "disconnecting"}…` : vpn.active ? "connected" : ""
                color: vpn.active && !vpn.busy ? Theme.accent : Theme.dim
            }

            Highlight {
                onClicked: S.Network.toggleVpn(vpn.modelData.uuid, vpn.active)
            }
        }
    }

    // Connection information
    Separator {
        visible: S.Network.connected
    }

    Label {
        visible: S.Network.connected
        text: "Connection Information"
        color: Theme.dim
    }

    Grid {
        visible: S.Network.connected
        columns: 2
        columnSpacing: 16
        rowSpacing: 4

        Label {
            text: "Interface"
            color: Theme.dim
        }
        Label {
            text: S.Network.iface
        }
        Label {
            text: "Speed"
            color: Theme.dim
        }
        Label {
            text: S.Network.speed || "—"
        }
        Label {
            text: "Security"
            color: Theme.dim
        }
        Label {
            text: S.Network.security || "—"
        }
        Label {
            text: "IPv4 Address"
            color: Theme.dim
        }
        Label {
            text: S.Network.localIp || "…"
        }
        Label {
            text: "Default Route"
            color: Theme.dim
        }
        Label {
            text: S.Network.gateway
        }
        Label {
            text: "Primary DNS"
            color: Theme.dim
        }
        Label {
            text: S.Network.dns || "—"
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
