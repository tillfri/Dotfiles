pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config

// Hover card for a tray icon: its title and its context menu. Submenus open in place (the header
// turns into a back button); entries stagger in each time the card opens or the menu changes.
Column {
    id: root

    // The hovered TrayItem (for its modelData and resolved icon); null once the icon is gone.
    required property Item target
    // True while the card is visible.
    property bool shown
    // Submenu entries descended into; the last one is shown.
    property var path: []
    readonly property QsMenuHandle menu: path.length ? path[path.length - 1] : target?.modelData.menu ?? null
    readonly property bool hasEntries: opener.children.values.length > 0
    readonly property string title: target?.modelData.tooltipTitle || target?.modelData.title || target?.modelData.id || ""
    // Some menus (Discord) already start with the app's name; skip the header then.
    readonly property bool showHeader: path.length > 0 || stripMnemonic(opener.children.values[0]?.text ?? "") !== title

    // A leaf entry was clicked.
    signal activated
    signal reveal

    // dbusmenu labels mark mnemonics with "_" ("__" is a literal underscore).
    function stripMnemonic(text: string): string {
        return text.replace(/__|_/g, m => m === "__" ? "_" : "");
    }

    width: Theme.trayMenuWidth
    spacing: 2

    onTargetChanged: path = []
    onShownChanged: {
        if (shown) {
            path = [];
            reveal();
        }
    }

    QsMenuOpener {
        id: opener

        menu: root.menu
    }

    // App icon and title; in a submenu, a back button named after it.
    Revealing {
        id: header

        readonly property bool inSubmenu: root.path.length > 0

        order: 0
        visible: root.showHeader
        width: root.width
        implicitHeight: 30

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18

                IconImage {
                    anchors.fill: parent
                    visible: !header.inSubmenu
                    source: root.target?.iconSource ?? ""
                }
                Label {
                    anchors.centerIn: parent
                    visible: header.inSubmenu
                    color: Theme.accent
                    text: "\u{f0141}"
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: root.width - 28
                elide: Text.ElideRight
                color: header.inSubmenu ? Theme.accent : Theme.fg
                text: header.inSubmenu ? root.stripMnemonic(root.path[root.path.length - 1].text) : root.title
            }
        }

        Highlight {
            enabled: header.inSubmenu
            onClicked: root.path = root.path.slice(0, -1)
        }
    }

    Rectangle {
        visible: root.showHeader && root.hasEntries
        width: root.width
        height: 1
        color: Theme.surfaceHover
    }

    Repeater {
        model: opener.children

        Entry {}
    }

    // One menu row: check/radio mark, icon, label, submenu chevron.
    component Entry: Revealing {
        id: entry

        required property QsMenuEntry modelData
        required property int index
        readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
        readonly property bool checked: modelData.checkState === Qt.Checked

        order: index + 1
        width: root.width
        implicitHeight: modelData.isSeparator ? 9 : 32

        Rectangle {
            anchors.centerIn: parent
            visible: entry.modelData.isSeparator
            width: parent.width
            height: 1
            color: Theme.surfaceHover
        }

        Row {
            id: leading

            anchors.verticalCenter: parent.verticalCenter
            visible: !entry.modelData.isSeparator
            spacing: 10

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.checkable
                color: entry.checked ? Theme.accent : Theme.dim
                text: entry.modelData.buttonType === QsMenuButtonType.RadioButton ? (entry.checked ? "\u{f043e}" : "\u{f043d}") : (entry.checked ? "\u{f0132}" : "\u{f0131}")
            }
            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: entry.modelData.icon !== ""
                implicitSize: 18
                source: entry.modelData.icon
            }
        }

        Label {
            anchors.left: leading.right
            anchors.leftMargin: leading.width > 0 ? 10 : 0
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !entry.modelData.isSeparator
            elide: Text.ElideRight
            color: entry.modelData.enabled ? Theme.fg : Theme.dim
            text: root.stripMnemonic(entry.modelData.text)
        }

        Label {
            id: chevron

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: entry.modelData.hasChildren
            width: visible ? implicitWidth : 0
            color: Theme.dim
            text: "\u{f0142}"
        }

        Highlight {
            enabled: !entry.modelData.isSeparator && entry.modelData.enabled
            onClicked: {
                if (entry.modelData.hasChildren) {
                    root.path = [...root.path, entry.modelData];
                } else {
                    entry.modelData.triggered();
                    root.activated();
                }
            }
        }
    }

    // Fades and drops in, `order` steps after the card opens or the menu changes.
    component Revealing: Item {
        id: revealing

        property int order

        Component.onCompleted: revealAnim.restart()

        transform: Translate {
            id: shift
        }

        Connections {
            target: root

            function onReveal(): void {
                revealAnim.restart();
            }
        }

        SequentialAnimation {
            id: revealAnim

            PropertyAction {
                target: revealing
                property: "opacity"
                value: 0
            }
            PropertyAction {
                target: shift
                property: "y"
                value: -8
            }
            PauseAnimation {
                duration: Math.min(revealing.order, 12) * 20
            }
            ParallelAnimation {
                EffectsAnim {
                    target: revealing
                    property: "opacity"
                    to: 1
                }
                SpatialAnim {
                    target: shift
                    property: "y"
                    to: 0
                }
            }
        }
    }

    // Clickable row background that lights up on hover.
    component Highlight: MouseArea {
        id: area

        anchors.fill: parent
        anchors.leftMargin: -6
        anchors.rightMargin: -6
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        z: -1

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: area.containsMouse && area.enabled ? Theme.surfaceHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.durationEffects
                }
            }
        }
    }

    component Label: StyledText {
        font.pixelSize: Theme.popupFontSize
    }
}
