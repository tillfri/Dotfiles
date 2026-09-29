import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.components
import qs.config

BarModule {
    visible: items.count > 0
    spacing: Theme.traySpacing

    Repeater {
        id: items

        model: ScriptModel {
            values: SystemTray.items.values.filter(i => i.status !== Status.Passive)
        }

        TrayItem {
            anchors.verticalCenter: parent?.verticalCenter
        }
    }
}
