import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.modules

PanelWindow {
    id: root

    required property ShellScreen modelData
    readonly property var conf: Theme.screens[modelData.name]
    // This screen's overlay; bar items reach it via QsWindow.window.popouts.
    required property Popouts popouts

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.marginTop
        left: Theme.marginH
        right: Theme.marginH
    }
    implicitHeight: conf.height
    exclusiveZone: conf.height + conf.exclusiveOffset
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.layer: WlrLayer.Top

    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.moduleMargin
        height: parent.height
        spacing: Theme.moduleMargin * 2

        Cpu {
            height: parent.height
        }
        Temperature {
            height: parent.height
        }
        Memory {
            height: parent.height
        }
    }

    Workspaces {
        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.moduleMargin
        height: parent.height
        spacing: Theme.moduleMargin * 2

        Focus {
            height: parent.height
        }
        Updates {
            height: parent.height
        }
        Network {
            height: parent.height
        }
        Tray {
            height: parent.height
        }
        Volume {
            height: parent.height
        }
        Mic {
            height: parent.height
        }
        Battery {
            height: parent.height
        }
        Clock {
            height: parent.height
        }
    }
}
