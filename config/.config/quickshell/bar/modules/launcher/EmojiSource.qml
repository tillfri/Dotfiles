import "../../utils/fzf.js" as Fzf
import QtQuick
import Quickshell
import Quickshell.Io

// Emoji search over assets/emoji.tsv (Unicode names plus CLDR keywords), read on first use.
Scope {
    id: root

    // In Unicode order: { emoji, name, keywords, order }.
    property var entries: []
    readonly property var byName: new Fzf.Finder(entries, {
        selector: e => e.name
    })
    // Like the apps' keywords: literal matches only, and worth less than the name.
    readonly property var byKeywords: new Fzf.Finder(entries, {
        fuzzy: false,
        selector: e => e.keywords
    })

    function load(): void {
        file.path = Quickshell.shellPath("assets/emoji.tsv");
    }

    function query(search: string): var {
        search = search.trim();
        if (search === "")
            return entries.slice(0, 80);

        const hits = {};
        for (const r of byName.find(search))
            hits[r.item.order] = {
                entry: r.item,
                score: r.score
            };
        for (const r of byKeywords.find(search)) {
            const hit = hits[r.item.order];
            if (!hit)
                hits[r.item.order] = {
                    entry: r.item,
                    score: r.score * 0.7
                };
            else
                hit.score = Math.max(hit.score, r.score * 0.7);
        }
        return Object.values(hits).sort((a, b) => b.score - a.score || a.entry.order - b.entry.order).slice(0, 80).map(h => h.entry);
    }

    FileView {
        id: file

        onLoaded: root.entries = text().split("\n").filter(l => l !== "" && !l.startsWith("#")).map((l, order) => {
            const [emoji, name, keywords] = l.split("\t");
            return {
                emoji,
                name,
                keywords: keywords ?? "",
                order
            };
        })
    }
}
