import QtQuick
import qs.components
import qs.config
import qs.services

BarModule {
    visible: SystemStats.tempPath !== ""

    StyledText {
        text: ` ${Math.round(SystemStats.temperature)}°C`
        color: SystemStats.temperature >= Theme.tempCritical ? Theme.critical : Theme.fg
    }
}
