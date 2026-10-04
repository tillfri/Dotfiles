import QtQuick
import QtQuick.Controls
import qs.components
import qs.config
import qs.services

// Month calendar: arrows or wheel change the month, clicking the title returns to today.
Card {
    id: root

    property int month: Time.date.getMonth()
    property int year: Time.date.getFullYear()
    property real wheelAccum: 0
    readonly property int cellSize: 34

    function reset(): void {
        month = Time.date.getMonth();
        year = Time.date.getFullYear();
    }

    function shift(delta: int): void {
        const d = new Date(year, month + delta, 1);
        month = d.getMonth();
        year = d.getFullYear();
    }

    WheelHandler {
        onWheel: e => {
            root.wheelAccum += e.angleDelta.y;
            while (Math.abs(root.wheelAccum) >= 120) {
                const dir = Math.sign(root.wheelAccum);
                root.wheelAccum -= dir * 120;
                root.shift(-dir);
            }
        }
    }

    Column {
        spacing: 4

        Item {
            width: grid.width
            height: prev.height

            IconButton {
                id: prev

                text: "\u{f0141}"
                onClicked: root.shift(-1)
            }

            MouseArea {
                anchors.centerIn: parent
                width: title.implicitWidth + 16
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: root.reset()

                StyledText {
                    id: title

                    anchors.centerIn: parent
                    font.pixelSize: Theme.popupFontSize
                    color: Theme.accent
                    text: new Date(root.year, root.month, 1).toLocaleDateString(grid.locale, "MMMM yyyy")
                }
            }

            IconButton {
                anchors.right: parent.right
                text: "\u{f0142}"
                onClicked: root.shift(1)
            }
        }

        DayOfWeekRow {
            width: grid.width
            locale: grid.locale
            padding: 0
            spacing: 0

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13
                color: model.day === 0 || model.day === 6 ? Theme.accent2 : Theme.dim
                text: model.shortName
            }
        }

        MonthGrid {
            id: grid

            month: root.month
            year: root.year
            // en_GB: English names, but weeks start on Monday (en_US starts on Sunday)
            locale: Qt.locale("en_GB")
            padding: 0
            spacing: 0

            delegate: Item {
                id: day

                required property var model
                readonly property bool weekend: model.date.getDay() === 0 || model.date.getDay() === 6

                implicitWidth: root.cellSize
                implicitHeight: root.cellSize - 4

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.height
                    height: width
                    radius: width / 2
                    visible: day.model.today

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: Theme.accent
                        }
                        GradientStop {
                            position: 1
                            color: Theme.accent2
                        }
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    font.pixelSize: Theme.popupFontSize
                    font.bold: day.model.today
                    opacity: day.model.month === grid.month ? 1 : 0.35
                    color: day.model.today ? Theme.wsFg : day.weekend ? Theme.accent2 : Theme.fg
                    text: day.model.day
                }
            }
        }
    }
}
