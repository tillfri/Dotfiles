import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    popout: "volume"
    onLeftClicked: Audio.toggleMute()
    onRightClicked: {
        popouts?.close();
        Quickshell.execDetached(["pavucontrol"]);
    }
    onScrolledUp: Audio.setVolume(Audio.volume + Audio.step)
    onScrolledDown: Audio.setVolume(Audio.volume - Audio.step)

    StyledText {
        text: Audio.sinkIcon
    }
}
