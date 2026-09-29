import QtQuick
import qs.components
import qs.services as S

BarModule {
    tooltip: S.Network.details
    onContainsMouseChanged: if (containsMouse) S.Network.refreshDetails()

    StyledText {
        text: S.Network.connected ? ` ${S.SystemStats.formatBytes(S.SystemStats.netDown)}  ${S.SystemStats.formatBytes(S.SystemStats.netUp)}` : " \u{f05aa} "
    }
}
