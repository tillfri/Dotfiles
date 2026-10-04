import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// Dashboard content (shown in the Popouts overlay under the workspaces): date/time with the focus
// timer, calendar, media.
// Keys, when opened with SUPER+I: Space plays/pauses the shown player, Tab / Shift+Tab switch
// the source, Esc closes.
RowLayout {
    id: root

    // True while the dashboard is open; the media card only polls then.
    property bool active

    function reset(): void {
        calendar.reset();
        media.reset();
    }

    spacing: Theme.popupSpacing
    focus: true

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Escape)
            Dash.close();
        else if (e.key === Qt.Key_Space)
            media.togglePlaying();
        else if (e.key === Qt.Key_Tab)
            media.cycle(1);
        else if (e.key === Qt.Key_Backtab)
            media.cycle(-1);
        else
            return;
        e.accepted = true;
    }

    DateTimeCard {
        Layout.fillHeight: true
    }
    CalendarCard {
        id: calendar

        Layout.fillHeight: true
    }
    MediaCard {
        id: media

        Layout.fillHeight: true
        active: root.active
    }
}
