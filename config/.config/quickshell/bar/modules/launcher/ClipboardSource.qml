import "../../utils/fzf.js" as Fzf
import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history from cliphist (was `cliphist list | wofi -d | cliphist decode | wl-copy`).
// Image entries get a thumbnail, decoded on demand into the runtime dir and removed on close.
Scope {
    id: root

    // Newest first: { id, text, image }.
    property var entries: []
    readonly property var finder: new Fzf.Finder(entries, {
        selector: e => e.text
    })
    readonly property string thumbDir: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-cliphist`
    // Entry id -> file url, once decoded.
    property var thumbs: ({})
    property var queue: []

    function load(): void {
        lister.running = true;
    }

    function query(search: string): var {
        return finder.find(search.trim()).map(r => r.item);
    }

    function copy(id: string): void {
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id]);
    }

    function remove(id: string): void {
        // cliphist reads the id off the start of a `list` line.
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete', "sh", id]);
        entries = entries.filter(e => e.id !== id);
    }

    function ensureThumb(id: string): void {
        if (thumbs[id] !== undefined || queue.includes(id))
            return;
        queue.push(id);
        decodeNext();
    }

    function decodeNext(): void {
        if (decoder.running || queue.length === 0)
            return;
        decoder.entry = queue[0];
        decoder.running = true;
    }

    Component.onDestruction: Quickshell.execDetached(["rm", "-rf", thumbDir])

    Process {
        id: lister

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => l.includes("\t")).map(l => {
                const tab = l.indexOf("\t");
                const preview = l.slice(tab + 1);
                // "[[ binary data 92 KiB png 727x132 ]]"
                const image = preview.match(/^\[\[ binary data (.+) (png|jpe?g|bmp|webp|gif) (\d+x\d+) \]\]$/);
                return {
                    id: l.slice(0, tab),
                    text: image ? `${image[2].toUpperCase()} image  ${image[3]}  ${image[1]}` : preview,
                    image: image !== null
                };
            })
        }
    }

    // One decode at a time, in the order the rows asked.
    Process {
        id: decoder

        property string entry

        command: ["sh", "-c", 'mkdir -p -m 700 "$2" && cliphist decode "$1" > "$2/$1"', "sh", entry, root.thumbDir]
        onExited: code => {
            if (code === 0) {
                const done = Object.assign({}, root.thumbs);
                done[entry] = `file://${root.thumbDir}/${entry}`;
                root.thumbs = done;
            }
            root.queue.shift();
            root.decodeNext();
        }
    }
}
