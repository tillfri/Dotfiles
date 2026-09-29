pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Trimmed from caelestia-shell services/Audio.qml.
Singleton {
    id: root

    readonly property real maxVolume: 1
    readonly property real step: 0.05

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    // Bar glyphs, shared by the bar icons and the hover popouts.
    readonly property string sinkIcon: {
        if (muted)
            return "";
        const formFactor = sink?.properties["device.form-factor"] ?? "";
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
        return levels[Math.min(levels.length - 1, Math.floor(Math.round(volume * 100) / (100 / levels.length)))];
    }
    readonly property string sourceIcon: sourceMuted ? "" : ""

    function clamp(v: real): real {
        return Math.max(0, Math.min(maxVolume, v));
    }

    function setVolume(v: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = clamp(v);
        }
    }

    function setSourceVolume(v: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = clamp(v);
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleSourceMute(): void {
        if (source?.ready && source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }
}
