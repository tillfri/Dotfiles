import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The idle dim on screens without a backlight (external monitors, where brightnessctl has nothing
// to set): a black layer over everything that fades in, takes no input and is gone on the first
// activity.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property ShellScreen modelData
        readonly property bool dimmed: Idle.dimmed && !Brightness.available

        screen: modelData
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-dim"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        visible: dimmed || shade.opacity > 0
        mask: Region {}

        // Fades in, but undims at once.
        onDimmedChanged: {
            fade.stop();
            if (dimmed)
                fade.start();
            else
                shade.opacity = 0;
        }

        Rectangle {
            id: shade

            anchors.fill: parent
            color: "black"
            opacity: 0
        }

        NumberAnimation {
            id: fade

            target: shade
            property: "opacity"
            to: Theme.idleDimOpacity
            duration: Theme.idleDimFade
        }
    }
}
