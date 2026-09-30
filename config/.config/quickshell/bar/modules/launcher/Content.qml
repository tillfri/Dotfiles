pragma ComponentBehavior: Bound

import "../../utils/fzf.js" as Fzf
import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The launcher card: search field over the results. What the field searches depends on the
// mode: apps by default ("=" calculates, ":" finds emoji, Tab lists an app's desktop actions),
// or the clipboard history / a script's menu when opened for those (services/Launcher.qml).
// Keys: Up/Down, Ctrl+J/K, Ctrl+N/P, PageUp/PageDown, Enter, Esc; Shift+Delete drops a clipboard entry.
Item {
    id: root

    // App whose desktop actions are listed; null otherwise.
    property DesktopEntry actionsOf: null
    // The search to come back to after leaving the actions.
    property string savedQuery
    readonly property string mode: {
        if (actionsOf)
            return "actions";
        if (Launcher.mode !== "apps")
            return Launcher.mode;
        return input.text.startsWith("=") ? "calc" : input.text.startsWith(":") ? "emoji" : "apps";
    }
    readonly property string term: mode === "calc" || mode === "emoji" ? input.text.slice(1) : input.text
    readonly property var menuFinder: new Fzf.Finder([...Launcher.menuItems], {})
    readonly property var results: {
        switch (mode) {
        case "actions":
            return Array.from(actionsOf.actions).filter(a => a.name.toLowerCase().includes(term.trim().toLowerCase())).map(a => ({
                        key: a.id,
                        title: a.name,
                        subtitle: actionsOf.name,
                        icon: a.icon || actionsOf.icon,
                        data: a
                    }));
        case "calc":
            // The result is part of the key so the row is replaced, not kept, when it changes.
            return term.trim() === "" ? [] : [
                {
                    key: `calc ${calc.result}`,
                    title: calc.result || "…",
                    subtitle: `${term.trim()}  ·  Enter copies the result`,
                    glyph: "\u{f00ec}",
                    data: calc.result
                }
            ];
        case "emoji":
            return emoji.query(term).map(e => ({
                        key: e.emoji,
                        title: e.name,
                        glyph: e.emoji,
                        data: e.emoji
                    }));
        case "clipboard":
            return clipboard.query(term).map(e => ({
                        key: e.id,
                        title: e.text,
                        image: e.image,
                        data: e.id
                    }));
        case "menu":
            return menuFinder.find(term.trim()).map(r => ({
                        key: r.item,
                        title: r.item,
                        data: r.item
                    }));
        default:
            return Apps.query(term).map(e => ({
                        key: e.id,
                        title: e.name,
                        subtitle: e.genericName || e.comment,
                        icon: e.icon,
                        hint: e.actions.length > 0,
                        data: e
                    }));
        }
    }
    readonly property bool empty: results.length === 0 && term.trim() !== ""
    readonly property int bodyHeight: empty ? Theme.launcherRowHeight : Math.min(results.length, Theme.launcherMaxRows) * Theme.launcherRowHeight
    readonly property string glyph: ({
            actions: "\u{f0142}",
            calc: "\u{f00ec}",
            emoji: "\u{f01f2}",
            clipboard: "\u{f014c}",
            menu: "\u{f035c}"
        })[mode] ?? "\u{f0349}"
    readonly property string placeholder: ({
            actions: `${actionsOf?.name ?? ""} actions…`,
            clipboard: "Clipboard history…",
            menu: Launcher.menuPrompt
        })[mode] ?? "Search apps…"

    function reset(): void {
        actionsOf = null;
        input.text = Launcher.initialQuery;
        input.forceActiveFocus();
        prepare();
    }

    // The clipboard list and the emoji table are only read once their mode is on.
    function prepare(): void {
        if (mode === "clipboard")
            clipboard.load();
        else if (mode === "emoji")
            emoji.load();
    }

    function activate(row: var): void {
        if (!row)
            return;
        switch (mode) {
        case "actions":
            Apps.launchAction(actionsOf, row.data);
            break;
        case "calc":
            if (row.data === "")
                return;
            Quickshell.execDetached(["wl-copy", "--", row.data]);
            break;
        case "emoji":
            Quickshell.execDetached(["wl-copy", "--", row.data]);
            break;
        case "clipboard":
            clipboard.copy(row.data);
            break;
        case "menu":
            Launcher.pick(row.data);
            return;
        default:
            Apps.launch(row.data);
        }
        Launcher.close();
    }

    function move(by: int): void {
        if (list.count > 0)
            list.currentIndex = (list.currentIndex + by + list.count) % list.count;
    }

    function page(by: int): void {
        list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + by * Theme.launcherMaxRows));
    }

    function leaveActions(): void {
        actionsOf = null;
        input.text = savedQuery;
    }

    function handleKey(e: KeyEvent): void {
        const ctrl = e.modifiers & Qt.ControlModifier;
        const row = results[list.currentIndex];
        if (e.key === Qt.Key_Escape) {
            if (actionsOf)
                leaveActions();
            else
                Launcher.close();
        } else if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
            move(1);
        } else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
            move(-1);
        } else if (e.key === Qt.Key_PageDown) {
            page(1);
        } else if (e.key === Qt.Key_PageUp) {
            page(-1);
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            activate(row);
        } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
            if (mode === "apps" && row?.hint) {
                savedQuery = input.text;
                actionsOf = row.data;
                input.text = "";
            }
        } else if (e.key === Qt.Key_Backspace && actionsOf && input.text === "") {
            leaveActions();
        } else if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier) && mode === "clipboard" && row) {
            const index = list.currentIndex;
            clipboard.remove(row.data);
            list.currentIndex = Math.min(index, list.count - 1);
        } else {
            return;
        }
        e.accepted = true;
    }

    implicitWidth: Theme.launcherWidth
    implicitHeight: Theme.launcherSearchHeight + (bodyHeight > 0 ? bodyHeight + 2 * Theme.popupSpacing + 1 : 0)
    onModeChanged: prepare()
    Component.onCompleted: reset()

    Connections {
        target: Launcher

        function onSessionChanged(): void {
            root.reset();
        }
    }

    ClipboardSource {
        id: clipboard
    }

    EmojiSource {
        id: emoji
    }

    CalcSource {
        id: calc

        expr: root.mode === "calc" ? root.term : ""
    }

    Item {
        id: search

        width: parent.width
        height: Theme.launcherSearchHeight

        StyledText {
            id: modeGlyph

            x: 20
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent
            font.pixelSize: 22
            text: root.glyph
        }

        TextInput {
            id: input

            anchors.left: modeGlyph.right
            anchors.leftMargin: 14
            anchors.right: total.left
            anchors.rightMargin: 12
            height: parent.height
            verticalAlignment: TextInput.AlignVCenter
            clip: true
            focus: true
            renderType: TextInput.NativeRendering
            color: Theme.fg
            selectionColor: Theme.accent
            selectedTextColor: Theme.wsFg
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.bold: true
            Keys.onPressed: e => root.handleKey(e)

            cursorDelegate: Rectangle {
                width: 2
                radius: 1
                color: Theme.accent

                SequentialAnimation on opacity {
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 500
                    }
                    EffectsAnim {
                        to: 0
                    }
                    PauseAnimation {
                        duration: 250
                    }
                    EffectsAnim {
                        to: 1
                    }
                }
            }
        }

        StyledText {
            anchors.fill: input
            anchors.leftMargin: 4
            visible: input.text === ""
            elide: Text.ElideRight
            color: Theme.dim
            font.bold: false
            text: root.placeholder
        }

        StyledText {
            id: total

            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: root.results.length > 1
            color: Theme.dim
            font.pixelSize: Theme.launcherSubSize
            font.bold: false
            text: root.results.length
        }
    }

    // The workspace pills' gradient, as a hairline between the field and the results.
    Rectangle {
        x: Theme.popupSpacing
        y: search.height
        width: parent.width - 2 * x
        height: 1
        visible: root.bodyHeight > 0
        opacity: 0.6
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Theme.wsGradientActive[0]
            }
            GradientStop {
                position: 0.5
                color: Theme.wsGradientActive[1]
            }
            GradientStop {
                position: 1
                color: Theme.wsGradientActive[2]
            }
        }
    }

    ListView {
        id: list

        x: Theme.popupSpacing
        y: search.height + 1 + Theme.popupSpacing
        width: parent.width - 2 * x
        height: root.bodyHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        model: ScriptModel {
            values: root.results
            // Rows are rebuilt on every keystroke; matching them by key keeps the ones that stay.
            objectProp: "key"
            onValuesChanged: list.currentIndex = 0
        }

        delegate: ResultRow {
            thumb: modelData.image ? clipboard.thumbs[modelData.data] ?? "" : ""
            // Only real pointer movement selects, not rows sliding under a resting pointer.
            onPositionChanged: list.currentIndex = index
            onClicked: root.activate(modelData)
            Component.onCompleted: {
                if (modelData.image)
                    clipboard.ensureThumb(modelData.data);
            }
        }

        // caelestia's launcher highlight: one rectangle that slides to the current row.
        highlight: Rectangle {
            y: list.currentItem?.y ?? 0
            width: list.width
            height: Theme.launcherRowHeight
            visible: list.currentItem !== null
            radius: 8
            color: Theme.surfaceHover

            Behavior on y {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curveStandard
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: parent.height - 22
                radius: 1.5
                gradient: Gradient {
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
        }

        add: Transition {
            EffectsAnim {
                property: "opacity"
                from: 0
                to: 1
            }
        }
        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: 80
            }
        }
        displaced: Transition {
            Slide {}
            // A row pushed away mid fade-in would otherwise stay half transparent.
            EffectsAnim {
                property: "opacity"
                to: 1
            }
        }
        move: Transition {
            Slide {}
            EffectsAnim {
                property: "opacity"
                to: 1
            }
        }
    }

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: list.y
        height: Theme.launcherRowHeight
        visible: root.empty
        color: Theme.dim
        font.pixelSize: Theme.launcherFontSize
        font.bold: false
        text: "No results"
    }

    component Slide: NumberAnimation {
        property: "y"
        duration: 150
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Theme.curveStandard
    }
}
