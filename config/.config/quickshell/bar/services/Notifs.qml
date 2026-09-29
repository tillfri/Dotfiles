pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

// Replaces swaync's daemon (trimmed from caelestia-shell services/Notifs.qml): owns
// org.freedesktop.Notifications, keeps the list for the center and decides what pops up.
Singleton {
    id: root

    // Entries, newest first. Each keeps a copy of its notification's fields, so cards can still
    // animate out after the app closed it.
    property list<Entry> list: []
    readonly property list<Entry> popups: list.filter(n => n.popup)
    property bool centerOpen
    property alias dnd: props.dnd

    // swaync's notification-visibility "muted": no popup, but kept in the center.
    function muted(n: Notification): bool {
        return Theme.notifMuted.some(r => r.app === n.appName && r.urgency === n.urgency);
    }

    function shouldPopup(n: Notification): bool {
        // lastGeneration: carried over from before a config reload, so it was already shown.
        return !n.lastGeneration && !centerOpen && !muted(n) && (!dnd || n.urgency === NotificationUrgency.Critical);
    }

    // Animate the card out, then close the notification.
    function dismiss(entry: Entry): void {
        entry.leaving = true;
        entry.leaveTimer.start();
    }

    function clearAll(): void {
        for (const entry of list)
            dismiss(entry);
    }

    function setCenterOpen(open: bool): void {
        centerOpen = open;
        // Opening the center takes over from the popups, like swaync.
        if (open) {
            for (const entry of list)
                entry.popup = false;
        }
    }

    function remove(entry: Entry): void {
        list = list.filter(e => e !== entry);
        entry.destroy(Theme.durationSpatial * 2);
    }

    function add(n: Notification, popup: bool): void {
        if (list.some(e => e.notification === n))
            return;
        // Replace-by-hint (volume/brightness scripts): drop the previous one with the same tag.
        const tag = n.hints["x-canonical-private-synchronous"];
        if (tag) {
            for (const e of list) {
                if (e.hints["x-canonical-private-synchronous"] === tag)
                    e.notification?.dismiss();
            }
        }
        list = [entryComp.createObject(root, {
                notification: n,
                popup
            }), ...list];
    }

    // Notifications kept across a reload (keepOnReload) come back without popups.
    Component.onCompleted: {
        for (const n of server.trackedNotifications.values)
            add(n, false);
    }

    PersistentProperties {
        id: props

        property bool dnd

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            root.add(n, root.shouldPopup(n));
        }
    }

    IpcHandler {
        target: "notifs"

        function toggle(): void {
            root.setCenterOpen(!root.centerOpen);
        }

        function open(): void {
            root.setCenterOpen(true);
        }

        function close(): void {
            root.setCenterOpen(false);
        }

        function clear(): void {
            root.clearAll();
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }
    }

    Component {
        id: entryComp

        Entry {}
    }

    component Entry: QtObject {
        id: entry

        required property Notification notification
        property bool popup
        // Set by a hovered popup; the expire timer waits for it.
        property bool paused
        // Animating out before the notification is closed.
        property bool leaving
        property date time: new Date()

        property string summary
        property string body
        property string appName
        property string appIcon
        property string image
        property int urgency
        property bool resident
        property var hints: ({})
        property var actions: []

        function sync(): void {
            const n = notification;
            if (!n)
                return;
            summary = n.summary;
            body = n.body;
            appName = n.appName;
            appIcon = n.appIcon || DesktopEntries.heuristicLookup(n.desktopEntry || n.appName)?.icon || "";
            image = n.image;
            urgency = n.urgency;
            resident = n.resident;
            hints = n.hints;
            actions = n.actions.map(a => ({
                        identifier: a.identifier,
                        text: a.text,
                        invoke: () => a.invoke()
                    }));
        }

        // An app replaced it in place (same id): show it again.
        function replaced(): void {
            time = new Date();
            if (root.shouldPopup(notification)) {
                popup = true;
                entry.expireTimer.restart();
            }
        }

        // swaync's timeout / timeout-low / timeout-critical; the app's own timeout (seconds) wins.
        readonly property Timer expireTimer: Timer {
            running: entry.popup && !entry.paused
            interval: (entry.notification?.expireTimeout ?? 0) > 0 ? entry.notification.expireTimeout * 1000 : Theme.notifTimeout[entry.urgency] ?? 8000
            onTriggered: entry.popup = false
        }

        readonly property Timer leaveTimer: Timer {
            interval: Theme.durationEffects + 100
            onTriggered: {
                if (entry.notification)
                    entry.notification.dismiss();
                else
                    root.remove(entry);
            }
        }

        readonly property Connections conn: Connections {
            target: entry.notification

            function onClosed(): void {
                root.remove(entry);
            }

            function onSummaryChanged(): void {
                entry.sync();
                entry.replaced();
            }

            function onBodyChanged(): void {
                entry.sync();
                entry.replaced();
            }

            function onAppIconChanged(): void {
                entry.sync();
            }

            function onImageChanged(): void {
                entry.sync();
            }

            function onActionsChanged(): void {
                entry.sync();
            }

            function onHintsChanged(): void {
                entry.sync();
            }
        }

        Component.onCompleted: sync()
    }
}
