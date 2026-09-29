import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// MPRIS player: source pills (when there are several), cover, title/artist, progress, prev/play/next.
Card {
    id: root

    // Only poll the position while the dashboard is actually open.
    property bool active
    // Picked in the source pills; the default (playing / last playing) player until then.
    property MprisPlayer selected
    readonly property MprisPlayer player: Players.players.includes(selected) ? selected : Players.active
    readonly property int contentWidth: 200

    // Called when the dashboard opens, so it starts on the default player again.
    function reset(): void {
        selected = null;
    }

    visible: player !== null
    onPlayerChanged: switchAnim.restart()

    // MPRIS doesn't signal position changes while playing; poll it like caelestia does.
    Timer {
        running: root.active && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    // Brief fade/settle of the details when the source changes.
    ParallelAnimation {
        id: switchAnim

        EffectsAnim {
            target: details
            property: "opacity"
            from: 0
            to: 1
        }
        SpatialAnim {
            target: details
            property: "scale"
            from: 0.96
            to: 1
        }
    }

    Column {
        spacing: Theme.popupSpacing

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Players.players.length > 1
            spacing: 4

            Repeater {
                model: Players.players

                SourcePill {}
            }
        }

        Column {
            id: details

            spacing: Theme.popupSpacing

            ClippingRectangle {
                width: root.contentWidth
                height: width
                radius: Theme.popupRadius
                color: Theme.surface

                Image {
                    id: cover

                    anchors.fill: parent
                    source: Players.artUrl(root.player)
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

    // One source: app icon, plus the label for the shown one (slides open); dot while playing.
    component SourcePill: MouseArea {
        id: pill

        required property MprisPlayer modelData
        readonly property bool current: modelData === root.player
        readonly property string iconPath: Players.icon(modelData)

        implicitWidth: pillRow.implicitWidth + 20
        implicitHeight: 28
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected = modelData

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: pill.current ? Qt.alpha(Theme.accent, 0.22) : pill.containsMouse ? Theme.surfaceHover : Theme.surface

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }

        Row {
            id: pillRow

            x: 10
            anchors.verticalCenter: parent.verticalCenter

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16

                IconImage {
                    anchors.fill: parent
                    visible: pill.iconPath !== ""
                    source: pill.iconPath
                }
                StyledText {
                    anchors.centerIn: parent
                    visible: pill.iconPath === ""
                    font.pixelSize: 14
                    color: pill.current ? Theme.accent : Theme.fg
                    text: "\u{f075a}"
                }
            }

            // Width animates between 0 and the (capped) label width, clipping the text.
            Item {
                // Room left for the label after the other (collapsed) pills.
                readonly property real maxWidth: Math.max(0, root.contentWidth - (Players.players.length - 1) * (16 + 20 + 4) - 16 - 20)

                anchors.verticalCenter: parent.verticalCenter
                width: pill.current ? Math.min(label.implicitWidth + 6, maxWidth) : 0
                height: label.implicitHeight
                clip: true

                Behavior on width {
                    SpatialAnim {}
                }

                StyledText {
                    id: label

                    x: 6
                    width: parent.maxWidth - 6
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: Theme.accent
                    opacity: pill.current ? 1 : 0
                    text: Players.label(pill.modelData)

                    Behavior on opacity {
                        EffectsAnim {}
                    }
                }
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 3
            width: 6
            height: 6
            radius: 3
            color: Theme.accent2
            scale: pill.modelData.isPlaying ? 1 : 0

            Behavior on scale {
                SpatialAnim {}
            }
        }
    }
}
