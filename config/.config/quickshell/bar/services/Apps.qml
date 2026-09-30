pragma Singleton

import "../utils/fzf.js" as Fzf
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// App search for the launcher: fzf over the desktop entries (caelestia's Searcher), ranked with
// DankMaterialShell's frecency so the apps used most and most recently come first.
Singleton {
    id: root

    readonly property var list: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    // The indexes only rebuild when the installed apps change, not per keystroke.
    readonly property var byName: new Fzf.Finder(list, {
        selector: e => e.name
    })
    // Generic name and keywords only match literally: fuzzy hits in those long strings are noise.
    readonly property var byExtra: new Fzf.Finder(list, {
        fuzzy: false,
        selector: e => `${e.genericName} ${(e.keywords ?? []).join(" ")} ${e.id}`
    })
    // Desktop entry id -> { count, last (ms since epoch) }.
    property var usage: ({})

    // Launch count, capped at 10, weighted by how long ago the last launch was: 0..1000.
    function frecency(id: string): real {
        const u = usage[id];
        if (!u)
            return 0;
        const days = (Date.now() - u.last) / 86400000;
        const weight = days <= 4 ? 100 : days <= 14 ? 70 : days <= 31 ? 50 : days <= 90 ? 30 : 10;
        return weight * Math.min(u.count, 10);
    }

    function query(search: string): var {
        search = search.trim().replace(/\s+/g, " ");
        if (search === "")
            return [...list].sort((a, b) => frecency(b.id) - frecency(a.id) || a.name.localeCompare(b.name));

        // A hit in the generic name or keywords counts less than one in the name.
        const hits = {};
        for (const r of byName.find(search))
            hits[r.item.id] = {
                entry: r.item,
                score: r.score
            };
        for (const r of byExtra.find(search)) {
            const hit = hits[r.item.id];
            if (!hit)
                hits[r.item.id] = {
                    entry: r.item,
                    score: r.score * 0.7
                };
            else
                hit.score = Math.max(hit.score, r.score * 0.7);
        }
        // Usage lifts a match by up to half: a daily app found by keyword beats a stranger's name.
        const ranked = Object.values(hits);
        for (const hit of ranked)
            hit.score *= 1 + 0.5 * frecency(hit.entry.id) / 1000;
        return ranked.sort((a, b) => b.score - a.score || a.entry.name.length - b.entry.name.length || a.entry.name.localeCompare(b.entry.name)).map(h => h.entry);
    }

    function launch(entry: DesktopEntry): void {
        bump(entry.id);
        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: [...Theme.launcherTerminal, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            entry.execute();
    }

    function launchAction(entry: DesktopEntry, action: DesktopAction): void {
        bump(entry.id);
        action.execute();
    }

    function bump(id: string): void {
        const next = Object.assign({}, usage);
        next[id] = {
            count: (usage[id]?.count ?? 0) + 1,
            last: Date.now()
        };
        usage = next;
        store.setText(JSON.stringify(next));
    }

    FileView {
        id: store

        path: Quickshell.statePath("launcher.json")
        // Missing until the first launch.
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                console.warn("launcher: ignoring unreadable usage file:", e);
            }
        }
    }
}
