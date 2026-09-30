import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// One notification in the swaync nova-dark look: image/icon, summary + age, body, progress
// (`value` hint), action buttons, and a close button on hover. Click runs the default action;
// drag sideways to dismiss. `center` switches to the control center's row style.
Item {
    id: root

    required property var entry
    property bool center
    property bool expanded
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: entry.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: entry.actions.filter(a => a.identifier !== "default")
    readonly property bool hovered: hover.hovered
    readonly property int padding: center ? 12 : 20
    // Drag offset, and which side a dismissed card leaves to.
    property real dragX
    property int leaveDir: 1

    readonly property string iconSource: {
        const i = entry.appIcon;
        if (!i)
            return "";
        if (i.startsWith("/"))
            return `file://${i}`;
        return i.includes("://") ? i : Quickshell.iconPath(i, true);
    }
    readonly property string imageSource: entry.image.startsWith("/") ? `file://${entry.image}` : entry.image
    readonly property string age: {
        const m = Math.floor((Time.date - entry.time) / 60000);
        if (m < 1)
            return "now";
        if (m < 60)
            return `${m}m`;
        const h = Math.floor(m / 60);
        return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
    }

    implicitHeight: card.implicitHeight
    opacity: entry.leaving ? 0 : 1

    Behavior on opacity {
        EffectsAnim {}
    }

    // box-shadow: 0 0 8px 0 rgba(0,0,0,.6) (popups only; the center has its own).
    RectangularShadow {
        anchors.fill: card
        visible: !root.center
        radius: card.radius
        blur: 8
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    Rectangle {
        id: card

        x: root.entry.leaving ? root.leaveDir * (root.width + 32) : root.dragX
        width: root.width
        implicitHeight: content.implicitHeight + root.padding * 2
        color: root.center ? Theme.notifRow : Theme.notifBg
        radius: root.center ? Theme.notifRowRadius : Theme.notifRadius
        border.width: root.critical ? 2 : root.center ? 0 : 1
        border.color: Theme.notifCardBorder

        Behavior on x {
            enabled: !area.pressed

            SpatialAnim {}
        }

        Behavior on implicitHeight {
            SpatialAnim {}
        }

        HoverHandler {
            id: hover

            onHoveredChanged: root.entry.paused = hovered
        }

        // Click and drag-to-dismiss over the whole card (buttons inside sit on top).
        MouseArea {
            id: area

            property real startX
            property bool dragged

            anchors.fill: parent
            cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
            preventStealing: true

            onPressed: e => {
                startX = e.x;
                dragged = false;
            }
            onPositionChanged: e => {
                const dx = e.x - startX;
                if (Math.abs(dx) > 8)
                    dragged = true;
                if (dragged)
                    root.dragX += dx;
            }
            onReleased: {
                if (Math.abs(root.dragX) > root.width * 0.3) {
                    root.leaveDir = root.dragX < 0 ? -1 : 1;
                    Notifs.dismiss(root.entry);
                } else {
                    root.dragX = 0;
                }
            }
            onClicked: {
                if (dragged)
                    return;
                if (root.defaultAction)
                    root.defaultAction.invoke();
                else if (!root.center)
                    root.entry.popup = false;
            }
        }

        Row {
            id: content

            x: root.padding
            y: root.padding
            spacing: root.center ? 12 : 20

            Item {
                width: Theme.notifIconSize
                height: Theme.notifIconSize

                ClippingRectangle {
                    anchors.fill: parent
                    visible: root.imageSource !== ""
                    radius: 12
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        source: root.imageSource
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                    }
                }

                IconImage {
                    anchors.fill: parent
                    visible: root.imageSource === "" && root.iconSource !== ""
                    source: root.iconSource
                    asynchronous: true
                }

                StyledText {
                    anchors.centerIn: parent
                    visible: root.imageSource === "" && root.iconSource === ""
                    font.pixelSize: 32
                    color: Theme.dim
                    text: "\u{f009a}"
                }
            }

            Column {
                width: card.width - root.padding * 2 - Theme.notifIconSize - content.spacing
                spacing: 4

                // Summary and age; on hover the close/expand buttons take the age's place.
                Item {
                    width: parent.width
                    height: summary.implicitHeight

                    StyledText {
                        id: summary

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: Math.max(age.implicitWidth, root.hovered ? buttonsRow.width - root.padding + 8 : 0) + 8
                        elide: Text.ElideRight
                        font.pixelSize: Theme.notifFontSize
                        font.weight: Font.ExtraBold
                        text: root.entry.summary || root.entry.appName
                    }

                    StyledText {
                        id: age

                        anchors.right: parent.right
                        anchors.verticalCenter: summary.verticalCenter
                        opacity: root.hovered ? 0 : 1
                        font.pixelSize: 12
                        font.bold: false
                        color: Theme.dim
                        text: root.age

                        Behavior on opacity {
                            EffectsAnim {}
                        }
                    }
                }

                StyledText {
                    id: body

                    width: parent.width
                    visible: text !== ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: root.expanded ? 40 : 3
                    elide: Text.ElideRight
                    font.pixelSize: Theme.notifBodySize
                    font.bold: false
                    linkColor: Theme.accent
                    text: root.entry.body
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                // Progress from the `value` hint (0-100).
                Rectangle {
                    readonly property var value: root.entry.hints.value

                    visible: value !== undefined
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Theme.surfaceHover

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, parent.value ?? 0)) / 100
                        height: parent.height
                        radius: parent.radius
                        color: Theme.notifBorder

                        Behavior on width {
                            SpatialAnim {}
                        }
                    }
                }

                RowLayout {
                    visible: root.buttons.length > 0
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.buttons

                        MouseArea {
                            id: action

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 36
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.invoke()

                            Rectangle {
                                anchors.fill: parent
                                radius: root.center ? 12 : 8
                                color: root.center ? Qt.rgba(1, 1, 1, action.containsMouse ? 0.3 : 0.15) : action.containsMouse ? Theme.notifButtonHover : Theme.notifButton
                                border.width: 1
                                border.color: action.containsMouse && !root.center ? Theme.notifBorder : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.durationEffects
                                    }
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                width: Math.min(implicitWidth, parent.width - 12)
                                elide: Text.ElideRight
                                font.pixelSize: Theme.notifBodySize
                                text: action.modelData.text
                            }
                        }
                    }
                }
            }
        }

        // Expand (when the body is cut off) and close, shown while hovered.
        Row {
            id: buttonsRow

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 2
            opacity: root.hovered ? 1 : 0

            Behavior on opacity {
                EffectsAnim {}
            }

            CardButton {
                visible: body.truncated || root.expanded
                text: root.expanded ? "\u{f0143}" : "\u{f0140}"
                onClicked: root.expanded = !root.expanded
            }
            CardButton {
                text: "\u{f0156}"
                onClicked: Notifs.dismiss(root.entry)
            }
        }
    }

    component CardButton: MouseArea {
        id: button

        property alias text: glyph.text

        width: 26
        height: 26
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: button.containsMouse ? Theme.notifBorder : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }

        StyledText {
            id: glyph

            anchors.centerIn: parent
            font.pixelSize: 16
        }
    }
}
