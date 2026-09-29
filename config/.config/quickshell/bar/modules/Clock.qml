import QtQuick
import qs.components
import qs.modules.dashboard
import qs.services

BarModule {
    id: root

    onLeftClicked: dash.open = !dash.open

    StyledText {
        text: ` ${Time.format("hh:mm")}`
    }

    Dashboard {
        id: dash

        target: root
    }
}
