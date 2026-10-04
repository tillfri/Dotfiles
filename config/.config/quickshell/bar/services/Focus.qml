pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// Pomodoro timer shown in the dashboard (modules/dashboard/FocusTimer.qml), toggled by SUPER+C over IPC:
// work blocks with DND on, a short break after each and a long one after every Theme.focusCycles.
// Phases run against a wall-clock end time, so a suspend doesn't stretch them, and the state is
// persistent, so a config reload doesn't reset them. Finished work blocks are appended to logPath.
Singleton {
    id: root

    // "idle", "work", "short" or "long".
    readonly property string phase: props.phase
    // Work block within the round, 1..Theme.focusCycles.
    readonly property int cycle: props.cycle
    property alias workMinutes: props.workMinutes
    readonly property bool active: phase !== "idle"
    readonly property bool paused: props.pausedLeft >= 0
    // A work block is running (not paused): the bar keeps the screen awake then.
    readonly property bool working: phase === "work" && !paused
    property real now: Date.now()
    // Milliseconds left in the phase.
    readonly property real remaining: paused ? props.pausedLeft : Math.max(0, props.endsAt - now)
    // Finished work blocks today, from the log.
    readonly property int today: countDay === Time.format("yyyy-MM-dd") ? dayCount : 0
    property int dayCount
    property string countDay
    readonly property string logPath: `${Quickshell.env("HOME")}/.local/state/quickshell/focus.log`

    function minutes(p: string): int {
        return p === "work" ? workMinutes : p === "short" ? Theme.focusShort : Theme.focusLong;
    }

    // DND follows the work blocks; whatever it was before the first one comes back after.
    function begin(p: string): void {
        if (p === "work" && props.phase !== "work") {
            props.prevDnd = Notifs.dnd;
            Notifs.dnd = true;
        } else if (p !== "work" && props.phase === "work") {
            Notifs.dnd = props.prevDnd;
        }
        props.phase = p;
        props.pausedLeft = -1;
        now = Date.now();
        props.endsAt = now + minutes(p) * 60000;
    }

    function toggle(): void {
        if (!active) {
            props.cycle = 1;
            begin("work");
        } else if (paused) {
            now = Date.now();
            props.endsAt = now + props.pausedLeft;
            props.pausedLeft = -1;
        } else {
            props.pausedLeft = remaining;
        }
    }

    function stop(): void {
        begin("idle");
    }

    // Ends the phase early; a skipped work block isn't logged.
    function advance(finished: bool): void {
        if (phase === "work") {
            if (finished)
                log();
            const long = cycle >= Theme.focusCycles;
            begin(long ? "long" : "short");
            notify(long ? `Long break: ${Theme.focusLong} min` : `Break: ${Theme.focusShort} min`, `${today} ${today === 1 ? "session" : "sessions"} today`);
        } else if (active) {
            props.cycle = phase === "long" ? 1 : cycle + 1;
            begin("work");
            notify("Back to work", `Session ${cycle}/${Theme.focusCycles}: ${workMinutes} min`);
        }
    }

    // Scroll on the dashboard timer while stopped.
    function adjust(delta: int): void {
        if (!active)
            workMinutes = Math.max(5, Math.min(120, workMinutes + delta));
    }

    // Notifs lets the "Focus" app through DND, so the call back to work still pops up.
    function notify(summary: string, body: string): void {
        Quickshell.execDetached(["notify-send", "-a", "Focus", "-i", "alarm-timer", summary, body]);
    }

    function log(): void {
        const day = Time.format("yyyy-MM-dd");
        dayCount = today + 1;
        countDay = day;
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && printf "%s\\t%s\\n" "$2" "$3" >> "$1"', "sh", logPath, `${day}T${Time.format("hh:mm")}`, String(workMinutes)]);
    }

    PersistentProperties {
        id: props

        property string phase: "idle"
        property int cycle: 1
        property int workMinutes: Theme.focusWork
        property real endsAt
        // Milliseconds that were left when paused; -1 while running.
        property real pausedLeft: -1
        property bool prevDnd

        reloadableId: "focus"
        // A stray 0 restored from an earlier generation would end every block right away.
        onLoaded: {
            if (workMinutes < 5)
                workMinutes = Theme.focusWork;
        }
    }

    Timer {
        running: root.active && !root.paused
        repeat: true
        triggeredOnStart: true
        interval: 1000
        onTriggered: {
            root.now = Date.now();
            if (root.remaining <= 0)
                root.advance(true);
        }
    }

    // Today's count at startup; later ones are counted in memory.
    FileView {
        path: root.logPath
        // There is no log before the first finished block.
        printErrors: false
        onLoaded: {
            const day = Qt.formatDate(new Date(), "yyyy-MM-dd");
            root.dayCount = text().split("\n").filter(l => l.startsWith(day)).length;
            root.countDay = day;
        }
    }

    IpcHandler {
        target: "focus"

        // Starts a round, or pauses / resumes the running phase.
        function toggle(): void {
            root.toggle();
        }

        function stop(): void {
            root.stop();
        }

        function skip(): void {
            root.advance(false);
        }

        // "idle", or e.g. "work 1/4 12:34" with " paused" appended.
        function status(): string {
            if (!root.active)
                return "idle";
            const s = Math.ceil(root.remaining / 1000);
            return `${root.phase} ${root.cycle}/${Theme.focusCycles} ${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}${root.paused ? " paused" : ""}`;
        }
    }
}
