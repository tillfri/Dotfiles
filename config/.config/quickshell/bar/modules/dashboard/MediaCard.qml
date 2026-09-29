import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// Active MPRIS player: cover, title/artist, progress, prev/play/next.
Card {
    id: root

    readonly property MprisPlayer player: Players.active
    readonly property int contentWidth: 200

    visible: player !== null

    // MPRIS doesn't signal position changes while playing; poll it like caelestia does.
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    Column {
        spacing: Theme.popupSpacing

        ClippingRectangle {
            width: root.contentWidth
            height: width
            radius: Theme.popupRadius
            color: Theme.surface

            Image {
                id: cover

                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: width
                sourceSize.height: height
            }

            StyledText {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                font.pixelSize: 64
                color: Theme.dim
                text: "\u{f075a}"
            }
        }

        StyledText {
            width: root.contentWidth
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: Theme.popupFontSize
            text: root.player?.trackTitle || root.player?.identity || ""
        }

        StyledText {
            width: root.contentWidth
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.pixelSize: 13
            font.bold: false
            color: Theme.dim
            text: root.player?.trackArtist ?? ""
            visible: text !== ""
        }

        Rectangle {
            width: root.contentWidth
            height: 4
            radius: 2
            color: Theme.surfaceHover
            visible: root.player?.lengthSupported ?? false

            Rectangle {
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.popupSpacing

            IconButton {
                font.pixelSize: 22
                text: "\u{f04ae}"
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            IconButton {
                font.pixelSize: 22
                text: root.player?.isPlaying ? "\u{f03e4}" : "\u{f040a}"
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            IconButton {
                font.pixelSize: 22
                text: "\u{f04ad}"
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }
    }
}
