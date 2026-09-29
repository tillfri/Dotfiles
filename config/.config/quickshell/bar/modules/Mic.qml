import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    id: root

    onLeftClicked: Audio.toggleSourceMute()
    onRightClicked: {
        pop.close();
        Quickshell.execDetached(["pavucontrol"]);
    }
    onScrolledUp: Audio.setSourceVolume(Audio.sourceVolume + Audio.step)
    onScrolledDown: Audio.setSourceVolume(Audio.sourceVolume - Audio.step)

    StyledText {
        id: label

        text: Audio.sourceMuted ? "" : ""
    }

    HoverPopup {
        id: pop

        target: root

        AudioPopup {
            isSource: true
            icon: label.text
        }
    }
}
