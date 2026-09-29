import QtQuick
import QtQuick.Layouts
import qs.config

// Dashboard content (shown in the Popouts overlay under the workspaces): date/time, calendar, media.
RowLayout {
    id: root

    // True while the dashboard is open; the media card only polls then.
    property bool active

    function reset(): void {
        calendar.reset();
    }

    spacing: Theme.popupSpacing

    DateTimeCard {
        Layout.fillHeight: true
    }
    CalendarCard {
        id: calendar

        Layout.fillHeight: true
    }
    MediaCard {
        Layout.fillHeight: true
        active: root.active
    }
}
