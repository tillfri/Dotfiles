import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    onLeftClicked: Quickshell.execDetached(["kitty", "--start-as=fullscreen", "--title", "btop", "sh", "-c", "btop"])

    StyledText {
        text: ` ${Math.round(SystemStats.cpuPercent)}%`
    }
}
