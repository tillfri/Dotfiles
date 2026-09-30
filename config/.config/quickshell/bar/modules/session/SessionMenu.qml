pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

// The session menu (SUPER+ESC), replacing wlogout: a dimmed overlay over the focused screen with
// a grid of logout/shutdown/reboot/suspend/lock/hibernate tiles in the wlogout look. The selected
// tile wears the workspace bubbles' gradient, which slides over when the selection moves. Keys:
// the wlogout keybinds (E S R U L H) run an action right away; arrows/Tab move the selection,
// Enter or Space runs it; Esc, a click beside the tiles, or SUPER+ESC again closes the menu.
PanelWindow {
    id: root

    // caelestia's offsetScale: 0 = open, 1 = closed (faded out, tiles a little smaller).
    property real offsetScale: Session.open ? 0 : 1
    // Selected tile; back on the first one each time the menu opens.
    property int current: 0
    readonly property int count: Session.actions.length
    readonly property int columns: Theme.sessionColumns
    readonly property int rows: Math.ceil(count / columns)

    function move(dx: int, dy: int): void {
        const col = (current % columns + dx + columns) % columns;
        const row = (Math.floor(current / columns) + dy + rows) % rows;
        current = Math.min(row * columns + col, count - 1);
    }

    screen: Session.screen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: Session.open || offsetScale < 1
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Session.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Reset while hidden, so the highlight is already in place (not sliding) when the menu opens.
    onVisibleChanged: {
        if (!visible) {
            current = 0;
            Session.settle();
        }
    }

    Behavior on offsetScale {
        EffectsAnim {}
    }

    HyprlandFocusGrab {
        windows: [root]
        active: Session.open
        onCleared: Session.close()
    }

    // window { background-color: rgba(10, 10, 10, 0.3) }
    Rectangle {
        anchors.fill: parent
        color: Theme.sessionBg
        opacity: 1 - root.offsetScale
    }

    // Clicks beside the tiles close the menu.
    MouseArea {
        anchors.fill: parent
        onClicked: Session.close()
    }

    Item {
        id: grid

        readonly property real tileWidth: (width - (root.columns - 1) * Theme.sessionSpacing) / root.columns
        readonly property real tileHeight: (height - (root.rows - 1) * Theme.sessionSpacing) / root.rows

        function tileX(i: int): real {
            return (i % root.columns) * (tileWidth + Theme.sessionSpacing);
        }

        function tileY(i: int): real {
            return Math.floor(i / root.columns) * (tileHeight + Theme.sessionSpacing);
        }

        anchors.fill: parent
        anchors.margins: Theme.sessionMargin
        focus: true
        opacity: 1 - root.offsetScale
        scale: 1 - 0.04 * root.offsetScale

        Keys.onPressed: e => {
            if (!Session.open)
                return;
            const direct = Session.actions.find(a => a.key === e.key);
            if (direct && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                Session.pick(direct);
            else if (e.key === Qt.Key_Escape)
                Session.close();
            else if (e.key === Qt.Key_Left)
                root.move(-1, 0);
            else if (e.key === Qt.Key_Right)
                root.move(1, 0);
            else if (e.key === Qt.Key_Up)
                root.move(0, -1);
            else if (e.key === Qt.Key_Down)
                root.move(0, 1);
            else if (e.key === Qt.Key_Tab)
                root.current = (root.current + 1) % root.count;
            else if (e.key === Qt.Key_Backtab)
                root.current = (root.current - 1 + root.count) % root.count;
            else if ([Qt.Key_Return, Qt.Key_Enter, Qt.Key_Space].includes(e.key))
                Session.pick(Session.actions[root.current]);
            else
                return;
            e.accepted = true;
        }

        // The selection, under the tiles: a glowing gradient ring (the inside dimmed) that
        // follows the selected tile with the spatial overshoot.
        Item {
            id: highlight

            x: grid.tileX(root.current)
            y: grid.tileY(root.current)
            width: grid.tileWidth
            height: grid.tileHeight

            Behavior on x {
                enabled: root.visible

                SpatialAnim {}
            }
            Behavior on y {
                enabled: root.visible

                SpatialAnim {}
            }

            RectangularShadow {
                anchors.fill: parent
                offset.y: 8
                radius: Theme.sessionRadius
                blur: 24
                color: Theme.sessionGlow
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.sessionRadius
                opacity: Theme.sessionHighlightOpacity

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

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: Theme.sessionRadius - 3
                    color: Theme.sessionHighlightDim
                }
            }
        }

        Repeater {
            model: Session.actions

            Tile {}
        }
    }

    // wlogout's button: translucent rounded tile with a white border, icon at 25% of its width and
    // the label below. Selected, its own fill and border fade out for the highlight underneath.
    component Tile: MouseArea {
        id: tile

        required property var modelData
        required property int index
        readonly property bool active: root.current === index

        x: grid.tileX(index)
        y: grid.tileY(index)
        width: grid.tileWidth
        height: grid.tileHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Only on movement: a pointer resting on a tile when the menu opens keeps the first one.
        onPositionChanged: root.current = index
        onClicked: Session.pick(modelData)

        // box-shadow: 0 4px 8px 0 rgba(0,0,0,.2), 0 6px 20px 0 rgba(0,0,0,.19)
        RectangularShadow {
            anchors.fill: parent
            offset.y: 6
            radius: Theme.sessionRadius
            blur: 20
            color: Qt.rgba(0, 0, 0, 0.2)
            opacity: tile.active ? 0 : 1

            Behavior on opacity {
                EffectsAnim {}
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.sessionRadius
            color: Theme.sessionButton
            border.width: 3
            border.color: Theme.sessionBorder
            opacity: tile.active ? 0 : 1

            Behavior on opacity {
                EffectsAnim {}
            }
        }

        Image {
            anchors.centerIn: parent
            width: tile.width * Theme.sessionIconScale
            height: width
            fillMode: Image.PreserveAspectFit
            // Room for the grown size, so the selected icon stays sharp.
            sourceSize.width: width * 1.15
            sourceSize.height: height * 1.15
            smooth: true
            mipmap: true
            scale: tile.active ? 1.12 : 1
            opacity: tile.active ? 1 : 0.8
            source: Qt.resolvedUrl(`../../assets/session/${tile.modelData.label}.png`)

            Behavior on scale {
                SpatialAnim {}
            }
            Behavior on opacity {
                EffectsAnim {}
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            font.pixelSize: Theme.sessionFontSize
            font.bold: tile.active
            color: "#ffffff"
            text: tile.modelData.text
        }
    }
}
