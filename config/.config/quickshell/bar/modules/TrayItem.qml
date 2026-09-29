import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components
import qs.config

MouseArea {
    id: root

    required property SystemTrayItem modelData
    // nm-applet gets the network card instead of the plain tooltip.
    readonly property bool isNetwork: modelData.id === "nm-applet"

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

    function openMenu(): void {
        const p = mapToItem(null, 0, height);
        modelData.display(QsWindow.window, p.x, p.y);
    }

    implicitWidth: Theme.trayIconSize
    implicitHeight: Theme.trayIconSize
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onClicked: e => {
        if (isNetwork)
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
    onContainsMouseChanged: {
        if (isNetwork)
            QsWindow.window?.popouts?.setHover("network", root, containsMouse);
        if (containsMouse && !isNetwork)
            tipTimer.restart();
        else {
            tipTimer.stop();
            tip.shown = false;
        }
    }

    IconImage {
        anchors.fill: parent
        source: root.iconSource
    }

    Timer {
        id: tipTimer

        interval: 400
        onTriggered: tip.shown = true
    }

    Tooltip {
        id: tip

        target: root
        text: root.modelData.tooltipTitle || root.modelData.title
    }
}
