pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player to show: whichever is playing, else the one that played last.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer lastPlaying: null
    readonly property MprisPlayer active: players.find(p => p.isPlaying) ?? (players.includes(lastPlaying) ? lastPlaying : players[0] ?? null)

    onActiveChanged: {
        if (active?.isPlaying)
            lastPlaying = active;
    }
}
