pragma Singleton

import QtQuick
import Quickshell

// Ported from waybar's hyprland/workspaces "window-rewrite". Regexes must match the whole
// class/title. Title rules are checked before class rules so e.g. nvim inside kitty wins.
Singleton {
    readonly property string fallback: ""

    readonly property var titleRules: [
        [/n/, ""],
        [/OpenCode/, "\u{f014f}"],
        [/lg/, ""],
        [/Yazi: .*/, ""],
        [/✳ .*/, "\u{f014f}"],
    ]

    readonly property var classRules: [
        [/kitty/, ""],
        [/firefox/, ""],
        [/chromium/, ""],
        [/Spotify/, ""],
        [/discord/, ""],
        [/com\.mitchellh\.ghostty/, ""],
        [/org\.pwmt\.zathura/, ""],
        [/sioyek/, ""],
    ]

    function fullMatch(re: var, str: string): bool {
        const m = (str ?? "").match(re);
        return !!m && m.index === 0 && m[0].length === str.length;
    }

    function iconFor(cls: string, title: string): string {
        for (const [re, icon] of titleRules)
            if (fullMatch(re, title))
                return icon;
        for (const [re, icon] of classRules)
            if (fullMatch(re, cls))
                return icon;
        return fallback;
    }
}
