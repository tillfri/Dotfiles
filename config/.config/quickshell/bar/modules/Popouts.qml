import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.modules.dashboard
import qs.services as S

// Transparent overlay per screen, laid over the bar with the same anchors and margins so bar item
// coordinates map 1:1. It holds the drawers (like caelestia's drawers window); only their visible
// area takes input, everything else clicks through.
PanelWindow {
    id: root

    required property ShellScreen modelData
    required property int barHeight

    // Called by bar items: `name` selects the pane, `item` is what the card centres under.
    function setHover(name: string, item: Item, hovered: bool): void {
        (name === "dashboard" ? dash : popout).setHover(name, item, hovered);
    }

    function close(): void {
        popout.close();
    }

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.marginTop
        left: Theme.marginH
        right: Theme.marginH
    }
    // Room for the tallest drawer plus the spatial curve's overshoot.
    implicitHeight: barHeight + Math.max(popout.fullHeight, dash.fullHeight) + 24
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-popouts"
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        item: popout

        Region {
            item: dash
        }
    }

    // Volume, mic and network share one card that morphs between them.
    Drawer {
        id: popout

        readonly property Item pane: [volumePane, micPane, networkPane].find(p => p.name === current) ?? null
        readonly property bool networkShown: open && current === "network"

        y: root.barHeight
        contentWidth: pane?.implicitWidth ?? 0
        contentHeight: pane?.implicitHeight ?? 0

        // Keep VPN state fresh while the network pane is visible.
        onNetworkShownChanged: {
            S.Network.vpnWatchers += networkShown ? 1 : -1;
            if (networkShown) {
                S.Network.refreshDetails();
                S.Network.refreshVpns();
            }
        }
        Component.onDestruction: if (networkShown)
            S.Network.vpnWatchers--

        Pane {
            id: volumePane

            name: "volume"

            AudioPopup {
                isSource: false
                icon: S.Audio.sinkIcon
            }
        }

        Pane {
            id: micPane

            name: "mic"

            AudioPopup {
                isSource: true
                icon: S.Audio.sourceIcon
            }
        }

        Pane {
            id: networkPane

            name: "network"

            NetworkPopup {}
        }
    }

    Drawer {
        id: dash

        y: root.barHeight
        openDelay: Theme.dashOpenDelay
        radius: Theme.dashRadius
        onOpenChanged: {
            if (open)
                dashboard.reset();
        }

        Dashboard {
            id: dashboard

            active: dash.open
        }
    }

    // One pane per popout; the outgoing one fades out while the card resizes to the incoming one.
    component Pane: Item {
        required property string name
        readonly property bool shown: popout.current === name
        default property alias content: paneContent.data

        implicitWidth: paneContent.childrenRect.width
        implicitHeight: paneContent.childrenRect.height
        // Hidden panes stay laid out (so the card knows their size) but take no input.
        opacity: shown ? 1 : 0
        enabled: shown

        Behavior on opacity {
            EffectsAnim {}
        }

        Item {
            id: paneContent
        }
    }
}
