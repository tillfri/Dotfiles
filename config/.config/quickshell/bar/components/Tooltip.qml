import QtQuick
import Quickshell
import qs.config

// Styled like waybar's `tooltip` CSS; shown below `target`, centred.
PopupWindow {
    id: root

    required property Item target
    property string text
    property bool shown

    anchor.item: target
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 6
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide

    visible: shown && text !== ""
    color: "transparent"
    implicitWidth: bg.implicitWidth
    implicitHeight: bg.implicitHeight

    Rectangle {
        id: bg

        anchors.fill: parent
        implicitWidth: label.implicitWidth + 24
        implicitHeight: label.implicitHeight + 16
        opacity: Theme.tooltipOpacity
        color: Theme.tooltipBg
        radius: 10
        border.width: 2
        border.color: Theme.tooltipBorder

        StyledText {
            id: label

            anchors.centerIn: parent
            textFormat: Text.StyledText
            color: Theme.tooltipFg
            text: root.text
        }
    }
}
