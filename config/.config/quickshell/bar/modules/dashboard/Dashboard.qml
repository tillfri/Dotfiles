import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

// Dropdown under the workspaces on hover: date/time, calendar, media.
HoverPopup {
    id: root

    openDelay: Theme.dashOpenDelay
    radius: Theme.dashRadius
    onOpenChanged: {
        if (open)
            calendar.reset();
    }

    RowLayout {
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
            active: root.open
        }
    }
}
