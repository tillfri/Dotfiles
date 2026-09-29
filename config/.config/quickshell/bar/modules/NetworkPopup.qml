import QtQuick
import qs.components
import qs.config
import qs.services as S

// Hover card for the nm-applet tray icon: local IP and the saved VPNs (click to toggle).
Column {
    id: root

    spacing: Theme.popupSpacing
    width: Math.max(260, implicitWidth)

    StyledText {
        font.pixelSize: Theme.popupFontSize
        text: S.Network.connected ? `\u{f0200}  ${S.Network.iface}` : "\u{f0200}  Disconnected"
    }

    Grid {
        visible: S.Network.connected
        columns: 2
        columnSpacing: 16
        rowSpacing: 4

        Label {
            text: "Local IP"
            color: Theme.dim
        }
        Label {
            text: S.Network.localIp || "…"
        }
        Label {
            text: "Gateway"
            color: Theme.dim
        }
        Label {
            text: S.Network.gateway
        }
    }

    Rectangle {
        width: root.width
        height: 1
        color: Theme.surfaceHover
    }

    Label {
        text: "VPN"
        color: Theme.dim
    }

    Label {
        visible: S.Network.vpns.length === 0
        text: "No saved VPNs"
        color: Theme.dim
    }

    Repeater {
        model: S.Network.vpns

        MouseArea {
            id: vpn

            required property var modelData
            readonly property bool active: modelData.state === "activated"
            readonly property bool busy: modelData.state === "activating" || modelData.state === "deactivating"

            width: root.width
            implicitHeight: vpnRow.implicitHeight + 8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: S.Network.toggleVpn(modelData.uuid, active)

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: -6
                anchors.rightMargin: -6
                radius: 8
                color: vpn.containsMouse ? Theme.surfaceHover : "transparent"
            }

            Row {
                id: vpnRow

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
        }
    }

    component Label: StyledText {
        font.pixelSize: Theme.popupFontSize
    }
}
