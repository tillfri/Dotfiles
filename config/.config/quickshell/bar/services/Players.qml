pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The MPRIS player to show by default: the one that most recently started playing (while it still
// plays), else any playing one, else the last one that played.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer lastPlaying: null
    readonly property MprisPlayer active: lastPlaying?.isPlaying ? lastPlaying : players.find(p => p.isPlaying) ?? (players.includes(lastPlaying) ? lastPlaying : players[0] ?? null)

    // Short label for the source switcher: the site for browser players (they report the page
    // URL), else the app's name.
    function label(player: MprisPlayer): string {
        const app = `${player?.desktopEntry} ${player?.identity}`.toLowerCase();
        const browser = ["firefox", "librewolf", "zen", "chrom", "brave", "vivaldi", "edge", "opera"].some(b => app.includes(b));
        const host = browser ? (player.metadata["xesam:url"] ?? "").match(/^https?:\/\/(?:www\.)?([^/:#?]+)/)?.[1] : null;
        return host ?? player?.identity ?? "";
    }

    // Themed app icon path, or "" when the player has no desktop entry with an icon.
    function icon(player: MprisPlayer): string {
        // Reading the list makes calling bindings update once desktop entries have loaded.
        if (DesktopEntries.applications.values.length === 0)
            return "";
        const entry = DesktopEntries.heuristicLookup(player?.desktopEntry || player?.identity || "");
        return entry?.icon ? Quickshell.iconPath(entry.icon, true) : "";
    }

    // Cover art, falling back to the thumbnail for YouTube videos (from caelestia's Players).
    function artUrl(player: MprisPlayer): string {
        if (player?.trackArtUrl)
            return player.trackArtUrl;
        const id = (player?.metadata["xesam:url"] ?? "").match(/youtube\.com\/watch.*[?&]v=([\w-]{11})/)?.[1];
        return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData

            target: modelData
            Component.onCompleted: {
                if (modelData.isPlaying && !root.lastPlaying?.isPlaying)
                    root.lastPlaying = modelData;
            }

            function onIsPlayingChanged(): void {
                if (modelData.isPlaying)
                    root.lastPlaying = modelData;
            }
        }
    }
}
