//@ pragma UseQApplication

import QtQuick
import Quickshell
import qs.config

ShellRoot {
    Variants {
        model: Quickshell.screens.filter(s => Theme.screens[s.name] !== undefined)

        Bar {}
    }
}
