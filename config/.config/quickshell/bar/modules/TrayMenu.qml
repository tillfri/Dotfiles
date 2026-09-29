pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config

// Hover card for a tray icon: its title and its context menu. Hovering a submenu row expands its
// entries inline below it, like the cascading platform menu; submenus nested in those open in place
// (the header turns into a back button). Entries stagger in each time the card opens or the menu
// changes.
Column {
    id: root

    // The hovered TrayItem (for its modelData and resolved icon); null once the icon is gone.
    required property Item target
    // True while the card is visible.
    property bool shown
    // Submenu entries descended into; the last one is shown.
    property var path: []
    // The submenu row of the shown menu whose entries are expanded inline.
    property QsMenuEntry expanded
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
    onPathChanged: expanded = null
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

    // Hover intent: a row only expands (or collapses its sibling) once the pointer rests on it, so
    // passing over rows on the way down doesn't flicker submenus open.
    Timer {
        id: expandTimer

        property QsMenuEntry entry

        interval: 150
        onTriggered: root.expanded = entry?.hasChildren ? entry : null
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

    // A row of the shown menu; a submenu row carries its expanded entries below it.
    component Entry: Revealing {
        id: entry

        required property QsMenuEntry modelData
        required property int index
        readonly property bool expanded: root.expanded !== null && root.expanded === modelData

        order: index + 1
        width: root.width
        implicitHeight: row.height + (expanded ? subEntries.implicitHeight : 0)

        EntryRow {
            id: row

            width: parent.width
            modelData: entry.modelData
            expanded: entry.expanded
        }

        Column {
            id: subEntries

            y: row.height
            width: parent.width
            visible: entry.expanded

            QsMenuOpener {
                id: subOpener

                menu: entry.expanded ? entry.modelData : null
            }

            Repeater {
                model: subOpener.children

                SubEntry {}
            }
        }
    }

    // An entry of an expanded submenu, indented under it.
    component SubEntry: Revealing {
        id: subEntry

        required property QsMenuEntry modelData
        required property int index

        order: index + 1
        width: root.width
        implicitHeight: subRow.height

        EntryRow {
            id: subRow

            x: 16
            width: parent.width - x
            modelData: subEntry.modelData
            nested: true
        }
    }

    // One menu row: check/radio mark, icon, label, submenu chevron.
    component EntryRow: Item {
        id: entryRow

        required property QsMenuEntry modelData
        // In an expanded submenu: its own submenus open in place instead of expanding.
        property bool nested
        property bool expanded
        readonly property bool checkable: (modelData?.buttonType ?? QsMenuButtonType.None) !== QsMenuButtonType.None
        readonly property bool checked: modelData?.checkState === Qt.Checked
        readonly property bool separator: modelData?.isSeparator ?? false

        implicitHeight: separator ? 9 : 32

        Rectangle {
            anchors.centerIn: parent
            visible: entryRow.separator
            width: parent.width
            height: 1
            color: Theme.surfaceHover
        }

        Row {
            id: leading

            anchors.verticalCenter: parent.verticalCenter
            visible: !entryRow.separator
            spacing: 10

            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: entryRow.checkable
                color: entryRow.checked ? Theme.accent : Theme.dim
                text: entryRow.modelData?.buttonType === QsMenuButtonType.RadioButton ? (entryRow.checked ? "\u{f043e}" : "\u{f043d}") : (entryRow.checked ? "\u{f0132}" : "\u{f0131}")
            }
            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                visible: (entryRow.modelData?.icon ?? "") !== ""
                implicitSize: 18
                source: entryRow.modelData?.icon ?? ""
            }
        }

        Label {
            anchors.left: leading.right
            anchors.leftMargin: leading.width > 0 ? 10 : 0
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !entryRow.separator
            elide: Text.ElideRight
            color: entryRow.modelData?.enabled ? Theme.fg : Theme.dim
            text: root.stripMnemonic(entryRow.modelData?.text ?? "")
        }

        // Points down while expanded inline.
        Label {
            id: chevron

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: entryRow.modelData?.hasChildren ?? false
            width: visible ? implicitWidth : 0
            color: entryRow.expanded ? Theme.accent : Theme.dim
            text: "\u{f0142}"
            rotation: entryRow.expanded ? 90 : 0

            Behavior on rotation {
                EffectsAnim {}
            }
        }

        Highlight {
            enabled: !entryRow.separator && (entryRow.modelData?.enabled ?? false)
            onContainsMouseChanged: {
                if (entryRow.nested)
                    return;
                if (containsMouse) {
                    expandTimer.entry = entryRow.modelData;
                    expandTimer.restart();
                } else if (expandTimer.entry === entryRow.modelData) {
                    expandTimer.stop();
                }
            }
            onClicked: {
                const e = entryRow.modelData;
                if (e.hasChildren && !entryRow.nested) {
                    expandTimer.stop();
                    root.expanded = entryRow.expanded ? null : e;
                } else if (e.hasChildren) {
                    root.path = [...root.path, e];
                } else {
                    e.triggered();
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
