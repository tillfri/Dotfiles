import QtQuick
import qs.components
import qs.services as S

BarModule {
    visible: S.Updates.text !== ""
    onLeftClicked: S.Updates.update()

    StyledText {
        text: S.Updates.text
    }
}
