import QtQuick
import Quickshell
import qs.components
import qs.services

BarModule {
    id: root

    readonly property int percent: Math.round(Audio.volume * 100)
    readonly property string icon: {
        const formFactor = Audio.sink?.properties["device.form-factor"] ?? "";
        const byDevice = {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": ""
        };
        if (byDevice[formFactor])
            return byDevice[formFactor];
        const levels = ["", "", ""];
        return levels[Math.min(levels.length - 1, Math.floor(percent / (100 / levels.length)))];
    }

    tooltip: `${icon} at ${percent}%`
    onLeftClicked: Audio.toggleMute()
    onRightClicked: Quickshell.execDetached(["pavucontrol"])
    onScrolledUp: Audio.setVolume(Audio.volume + Audio.step)
    onScrolledDown: Audio.setVolume(Audio.volume - Audio.step)

    StyledText {
        text: Audio.muted ? "" : root.icon
    }
}
