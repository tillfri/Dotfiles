import QtQuick
import qs.components
import qs.config
import qs.services

// Big stacked clock like caelestia's dash/DateTime.qml, with the date below.
Card {
    Column {
        spacing: 0

        Big {
            text: Time.format("hh")
            color: Theme.accent
        }
        Big {
            text: "•••"
            color: Theme.accent2
            font.pixelSize: 28
        }
        Big {
            text: Time.format("mm")
            color: Theme.accent
        }

        Item {
            width: 1
            height: Theme.popupSpacing * 2
        }

        Small {
            text: Time.format("dddd")
        }
        Small {
            text: Time.format("d. MMMM")
            color: Theme.dim
        }
    }

    component Big: StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: 52
    }

    component Small: StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: Theme.popupFontSize
    }
}
