import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
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

    // Not modelData.display(): in quickshell 0.3.1 it over-unrefs the menu handle when the menu is
    // already loaded (the hover card holds it), which leaves the card's menu empty from then on.
    function openMenu(): void {
        if (!menuAnchor.visible)
            menuAnchor.open();
    }

    implicitWidth: Theme.trayIconSize
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
        source: root.iconSource
    }
}
