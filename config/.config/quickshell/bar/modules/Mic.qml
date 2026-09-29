import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    popout: "mic"
    onLeftClicked: Audio.toggleSourceMute()
    onRightClicked: {
        popouts?.close();
        Quickshell.execDetached(["pavucontrol"]);
    }
    onScrolledUp: Audio.setSourceVolume(Audio.sourceVolume + Audio.step)
    onScrolledDown: Audio.setSourceVolume(Audio.sourceVolume - Audio.step)

    StyledText {
        text: Audio.sourceIcon
    }
}
