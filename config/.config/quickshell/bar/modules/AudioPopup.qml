import QtQuick
import qs.components
import qs.config
import qs.services

// Hover card for Volume/Mic: mute button, slider, percentage.
Row {
    id: root

    required property bool isSource
    required property string icon
    readonly property real volume: isSource ? Audio.sourceVolume : Audio.volume
    readonly property bool muted: isSource ? Audio.sourceMuted : Audio.muted

    spacing: Theme.popupSpacing

    IconButton {
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.muted ? Theme.dim : Theme.fg
        onClicked: root.isSource ? Audio.toggleSourceMute() : Audio.toggleMute()
    }

    StyledSlider {
        anchors.verticalCenter: parent.verticalCenter
        value: root.volume
        step: Audio.step
        dimmed: root.muted
        onMoved: v => root.isSource ? Audio.setSourceVolume(v) : Audio.setVolume(v)
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        width: pctMetrics.width
        horizontalAlignment: Text.AlignRight
        font.pixelSize: Theme.popupFontSize
        color: root.muted ? Theme.dim : Theme.fg
        text: `${Math.round(root.volume * 100)}%`

        TextMetrics {
            id: pctMetrics

            font.family: Theme.fontFamily
            font.pixelSize: Theme.popupFontSize
            font.bold: true
            text: "100%"
        }
    }
}
