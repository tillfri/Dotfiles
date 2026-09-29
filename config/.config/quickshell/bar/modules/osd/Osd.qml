import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// Replaces swayosd: the media keys call `qs -c bar ipc call osd <fn>`, which changes the value and
// slides a card of caelestia-style vertical sliders in from the right edge of the focused screen.
// Only the slider for what changed is shown; others grow in if their key is pressed meanwhile.
PanelWindow {
    id: root

    property bool open
    property bool showVolume
    property bool showMic
    property bool showBrightness
    // The output device's name, after SUPER+M switched it.
    property bool showDevice
    // caelestia's offsetScale: 0 = on screen, 1 = past the right edge.
    property real offsetScale: open ? 0 : 1
    readonly property int gap: Theme.popupSpacing

    function show(what: string): void {
        if (what === "volume" || what === "device")
            showVolume = true;
        if (what === "mic")
            showMic = true;
        if (what === "brightness")
            showBrightness = true;
        if (what === "device")
            showDevice = true;
        open = true;
        hideTimer.restart();
    }

    screen: Hypr.focusedScreen
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    visible: open || offsetScale < 1
    // Fixed size (room for all three sliders and the device name) so the card never shifts while
    // rows come and go; only the card takes input.
    implicitWidth: Theme.marginH + 300
    implicitHeight: 3 * (Theme.osdSliderHeight + gap) + Theme.popupPadding * 2
    mask: Region {
        item: card
    }

    // Forget what was shown once fully hidden, so the next key starts with just its own slider.
    onOffsetScaleChanged: {
        if (offsetScale === 1)
            showVolume = showMic = showBrightness = showDevice = false;
    }

    Behavior on offsetScale {
        SpatialAnim {}
    }

    Timer {
        id: hideTimer

        interval: Theme.osdHideDelay
        onTriggered: {
            if (!hover.hovered)
                root.open = false;
        }
    }

    Rectangle {
        id: card

        anchors.verticalCenter: parent.verticalCenter
        x: root.width - Theme.marginH - width + (width + Theme.marginH + 8) * root.offsetScale
        implicitWidth: content.implicitWidth + Theme.popupPadding * 2
        implicitHeight: sliders.implicitHeight - root.gap + Theme.popupPadding * 2
        width: implicitWidth
        height: implicitHeight
        radius: Theme.osdSliderWidth / 2 + Theme.popupPadding
        color: Theme.popupBg
        border.width: 2
        border.color: Theme.tooltipBorder
        opacity: 1 - root.offsetScale

        HoverHandler {
            id: hover

            onHoveredChanged: {
                if (!hovered)
                    hideTimer.restart();
            }
        }

        Row {
            id: content

            // The first row's gap sits in the top padding.
            x: Theme.popupPadding
            y: Theme.popupPadding - root.gap

            // Output device name, sliding open to the left of the sliders.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: root.showDevice ? device.implicitWidth + Theme.popupPadding : 0
                height: device.implicitHeight
                clip: true

                Behavior on width {
                    SpatialAnim {}
                }

                Column {
                    id: device

                    spacing: 2
                    opacity: root.showDevice ? 1 : 0

                    Behavior on opacity {
                        EffectsAnim {}
                    }

                    StyledText {
                        font.pixelSize: 12
                        color: Theme.dim
                        text: "Output"
                    }
                    StyledText {
                        width: Math.min(implicitWidth, 200)
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        font.pixelSize: Theme.popupFontSize
                        // "HyperX Cloud III S Wireless Analog Stereo" -> "HyperX Cloud III S Wireless"
                        text: (Audio.sink?.description || Audio.sink?.name || "").replace(/ (Analog|Digital) Stereo.*$/, "")
                    }
                }
            }

            Column {
                id: sliders

                SliderRow {
                    active: root.showVolume

                    FilledSlider {
                        value: Audio.volume
                        icon: Audio.sinkIcon
                        dimmed: Audio.muted
                        onMoved: v => {
                            Audio.setVolume(v);
                            hideTimer.restart();
                        }
                    }
                }

                SliderRow {
                    active: root.showMic

                    FilledSlider {
                        value: Audio.sourceVolume
                        icon: Audio.sourceIcon
                        dimmed: Audio.sourceMuted
                        onMoved: v => {
                            Audio.setSourceVolume(v);
                            hideTimer.restart();
                        }
                    }
                }

                SliderRow {
                    active: root.showBrightness

                    FilledSlider {
                        value: Brightness.brightness
                        icon: ["\u{f00de}", "\u{f00df}", "\u{f00e0}"][Math.min(2, Math.floor(value * 3))]
                        onMoved: v => {
                            Brightness.set(v);
                            hideTimer.restart();
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osd"

        function volumeUp(): void {
            Audio.setVolume(Math.round((Audio.volume + Audio.step) * 100) / 100);
            root.show("volume");
        }

        function volumeDown(): void {
            Audio.setVolume(Math.round((Audio.volume - Audio.step) * 100) / 100);
            root.show("volume");
        }

        function toggleMute(): void {
            Audio.toggleMute();
            root.show("volume");
        }

        function toggleMic(): void {
            Audio.toggleSourceMute();
            root.show("mic");
        }

        function brightnessUp(): void {
            if (Brightness.available) {
                Brightness.change(1);
                root.show("brightness");
            }
        }

        function brightnessDown(): void {
            if (Brightness.available) {
                Brightness.change(-1);
                root.show("brightness");
            }
        }

        // After the default output was switched (scripts/volume --toggle-sink).
        function output(): void {
            root.show("device");
        }
    }

    // One slider slot; grows in/out (like caelestia's WrappedLoader) with a gap above it.
    component SliderRow: Item {
        property bool active
        default property alias slider: slot.data

        width: Theme.osdSliderWidth
        height: active ? Theme.osdSliderHeight + root.gap : 0
        visible: height > 0
        clip: true

        Behavior on height {
            SpatialAnim {}
        }

        Item {
            id: slot

            y: root.gap
            width: Theme.osdSliderWidth
            height: Theme.osdSliderHeight
            opacity: parent.active ? 1 : 0

            Behavior on opacity {
                EffectsAnim {}
            }
        }
    }
}
