import QtQuick
import qs.config

// Rounded inner panel with padding; content is centred when the card is stretched.
Rectangle {
    id: root

    default property alias content: inner.data
    property int padding: Theme.popupPadding

    implicitWidth: inner.width + padding * 2
    implicitHeight: inner.height + padding * 2
    color: Theme.surface
    radius: Theme.dashRadius

    Item {
        id: inner

        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}
