//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
// IconTheme: independent of QT_QPA_PLATFORMTHEME, as qt6ct on the thinkpad sets none (falls back to hicolor).

import QtQuick
import Quickshell
import qs.config
import qs.modules
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd

ShellRoot {
    Variants {
        model: Quickshell.screens.filter(s => Theme.screens[s.name] !== undefined)

        Scope {
            id: scope

            required property ShellScreen modelData

            Bar {
                modelData: scope.modelData
                popouts: popouts
            }

            Popouts {
                id: popouts

                modelData: scope.modelData
                barHeight: Theme.screens[scope.modelData.name].height
            }
        }
    }

    Osd {}
    Popups {}
    NotifCenter {}
    Spotlight {}
}
