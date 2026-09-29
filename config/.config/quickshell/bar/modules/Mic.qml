import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    tooltip: ` at ${Math.round(Audio.sourceVolume * 100)}%`
    onLeftClicked: Audio.toggleSourceMute()
    onRightClicked: Quickshell.execDetached(["pavucontrol"])
    onScrolledUp: Audio.setSourceVolume(Audio.sourceVolume + Audio.step)
    onScrolledDown: Audio.setSourceVolume(Audio.sourceVolume - Audio.step)

    StyledText {
        text: Audio.sourceMuted ? "" : ""
    }
}
