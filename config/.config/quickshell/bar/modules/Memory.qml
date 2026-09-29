import QtQuick
import qs.components
import qs.services

BarModule {
    StyledText {
        text: ` ${SystemStats.memUsedGiB.toFixed(1)}GiB`
    }
}
