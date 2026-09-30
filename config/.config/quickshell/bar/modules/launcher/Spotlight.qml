import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The launcher (SUPER+RETURN / SUPER+SPACE), replacing wofi: a spotlight card in the upper third
// of the focused screen, for apps, the clipboard history (SUPER+X) and script menus. Only mapped
// while open; a click outside, Esc, or the bind again closes it. The window keeps its full
// height and only the card inside grows with the results, so typing never resizes the surface.
PanelWindow {
    id: root

    // caelestia's offsetScale: 0 = open, 1 = closed (faded out, a little higher and smaller).
    property real offsetScale: Launcher.open ? 0 : 1
    // How far the card drops while it opens.
    readonly property int drop: 12

    screen: Launcher.screen
    anchors.top: true
    margins.top: Math.round((screen?.height ?? 1080) * Theme.launcherTop) - drop
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: Theme.launcherWidth
    implicitHeight: drop + Theme.launcherSearchHeight + Theme.launcherMaxRows * Theme.launcherRowHeight + 2 * Theme.popupSpacing + 1
    color: "transparent"
    visible: Launcher.open || offsetScale < 1
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    // OnDemand, not Exclusive: the grab below hands over the keyboard, and hyprland drops the grab
    // when a layer that is still mapped (reopened during its close animation) turns exclusive.
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Instantiate the singleton now, so the first open doesn't wait for the search index.
    Component.onCompleted: Apps
    // A menu pick is only reported now, with the card gone: what the script starts next
    // (slurp, hyprpicker) would otherwise catch it fading out.
    onVisibleChanged: {
        if (!visible)
            Launcher.settle();
    }

    mask: Region {
        item: panel
    }

    Behavior on offsetScale {
        EffectsAnim {}
    }

    HyprlandFocusGrab {
        windows: [root]
        active: Launcher.open
        onCleared: Launcher.close()
    }

    Rectangle {
        id: panel

        y: root.drop * (1 - root.offsetScale)
        width: parent.width
        height: content.item?.implicitHeight ?? Theme.launcherSearchHeight
        color: Theme.popupBg
        radius: Theme.dashRadius
        border.width: 2
        border.color: Theme.tooltipBorder
        opacity: 1 - root.offsetScale
        scale: 1 - 0.04 * root.offsetScale
        transformOrigin: Item.Top
        clip: true

        // Not while still closed: the card should appear at its size, not grow into it.
        Behavior on height {
            enabled: root.offsetScale < 1

            NumberAnimation {
                duration: Theme.durationEffects
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.curveStandard
            }
        }

        // Lives from the open to the end of the close animation.
        Loader {
            id: content

            anchors.fill: parent
            focus: true
            active: Launcher.open || root.visible
            sourceComponent: Content {}
        }
    }
}
