import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config

MouseArea {
    id: root

    required property SystemTrayItem modelData
    // nm-applet gets the network card; everything else its title and menu.
    readonly property string popout: modelData.id === "nm-applet" ? "network" : "tray"

    // From caelestia utils/Icons.qml getTrayIcon(): resolve "name?path=dir" icons.
    readonly property string iconSource: {
        let icon = modelData.icon;
        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            const file = name.slice(name.lastIndexOf("/") + 1);
            const themed = Quickshell.iconPath(file, true);
            icon = themed ? themed : Qt.resolvedUrl(`${path}/${file}`);
        }
        return icon;
    }

    // nm-applet and blueman get a Nerd Font glyph like the other modules, picked from the state
    // their icon name encodes; "" (an unknown state or another app) keeps the themed icon.
    readonly property string glyph: {
        const name = modelData.icon.split("?")[0].split("/").pop();
        if (modelData.id === "nm-applet") {
            // nm-signal-{00,25,50,75,100}[-secure]; the lock variants are left out, as nearly every network is secured.
            const signal = name.match(/^nm-signal-(\d+)/);
            if (signal)
                return ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"][Math.min(4, Math.round(parseInt(signal[1]) / 25))];
            if (name.includes("vpn"))
                return "\u{f0582}";
            if (name.startsWith("nm-stage"))
                return "\u{f092f}";
            if (name === "nm-device-wired")
                return "\u{f0200}";
            if (name === "nm-no-connection")
                return "\u{f05aa}";
        } else if (modelData.id === "blueman") {
            return ({
                    "blueman-tray": "\u{f00af}",
                    "blueman-active": "\u{f00b1}",
                    "blueman-disabled": "\u{f00b2}"
                })[name] ?? "";
        }
        return "";
    }

    // Not modelData.display(): in quickshell 0.3.1 it over-unrefs the menu handle when the menu is
    // already loaded (the hover card holds it), which leaves the card's menu empty from then on.
    function openMenu(): void {
        if (!menuAnchor.visible)
            menuAnchor.open();
    }

    implicitWidth: glyph ? glyphText.implicitWidth : Theme.trayIconSize
    implicitHeight: Theme.trayIconSize
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: e => {
        QsWindow.window?.popouts?.close();
        if (e.button === Qt.RightButton || (e.button === Qt.LeftButton && modelData.onlyMenu)) {
            if (modelData.hasMenu)
                openMenu();
        } else if (e.button === Qt.LeftButton) {
            modelData.activate();
        } else {
            modelData.secondaryActivate();
        }
    }
    onWheel: e => modelData.scroll(e.angleDelta.y / 120, false)
    onContainsMouseChanged: QsWindow.window?.popouts?.setHover(popout, root, containsMouse)

    QsMenuAnchor {
        id: menuAnchor

        menu: root.modelData.menu
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
    }

    IconImage {
        anchors.fill: parent
        visible: !root.glyph
        source: visible ? root.iconSource : ""
    }

    StyledText {
        id: glyphText

        anchors.centerIn: parent
        visible: root.glyph !== ""
        text: root.glyph
    }
}
