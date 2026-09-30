import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config

// One launcher result: a themed icon, glyph or thumbnail, then the title over a dim subtitle.
// Rows are { key, title, subtitle, icon | glyph | image, hint, data } (see Content.qml).
MouseArea {
    id: root

    required property var modelData
    required property int index
    // Url of the thumbnail for an `image` row, "" until it is decoded.
    property string thumb
    readonly property bool hasIcon: modelData.icon !== undefined
    readonly property string iconSource: {
        const icon = modelData.icon ?? "";
        if (icon === "")
            return "";
        return icon.startsWith("/") ? `file://${icon}` : Quickshell.iconPath(icon, true);
    }

    width: ListView.view?.width ?? 0
    height: Theme.launcherRowHeight
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    Item {
        id: lead

        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: root.modelData.image ? 64 : Theme.launcherIconSize
        height: Theme.launcherIconSize
        visible: root.hasIcon || root.modelData.image === true || root.modelData.glyph !== undefined

        IconImage {
            anchors.fill: parent
            visible: root.iconSource !== ""
            asynchronous: true
            source: root.iconSource
        }

        // No themed icon: the name's first letter.
        Rectangle {
            anchors.fill: parent
            visible: root.hasIcon && root.iconSource === ""
            radius: 8
            color: Theme.surfaceHover

            StyledText {
                anchors.centerIn: parent
                color: Theme.accent
                text: root.modelData.title.charAt(0).toUpperCase()
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: root.modelData.glyph !== undefined
            font.pixelSize: 24
            text: root.modelData.glyph ?? ""
        }

        Rectangle {
            anchors.fill: parent
            visible: root.modelData.image === true
            radius: 4
            color: Theme.surface

            Image {
                anchors.fill: parent
                anchors.margins: 1
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                sourceSize.width: 192
                sourceSize.height: 96
                source: root.thumb
            }
        }
    }

    Column {
        anchors.left: lead.visible ? lead.right : parent.left
        anchors.leftMargin: 12
        anchors.right: hint.visible ? hint.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        StyledText {
            width: parent.width
            elide: Text.ElideRight
            font.pixelSize: Theme.launcherFontSize
            text: root.modelData.title
        }

        StyledText {
            width: parent.width
            visible: text !== ""
            elide: Text.ElideRight
            color: Theme.dim
            font.pixelSize: Theme.launcherSubSize
            font.bold: false
            text: root.modelData.subtitle ?? ""
        }
    }

    // The app has desktop actions: Tab lists them.
    Rectangle {
        id: hint

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: hintLabel.implicitWidth + 12
        height: hintLabel.implicitHeight + 6
        visible: root.modelData.hint === true && root.ListView.isCurrentItem
        radius: 5
        color: Theme.surface

        StyledText {
            id: hintLabel

            anchors.centerIn: parent
            color: Theme.dim
            font.pixelSize: Theme.launcherSubSize
            text: "Tab \u{f0142}"
        }
    }
}
