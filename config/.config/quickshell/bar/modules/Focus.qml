import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services as S

// Pomodoro timer (services/Focus.qml): click starts, pauses or resumes, right click stops, scrolling
// while stopped sets the work length. Keeps the screen from idling while a work block runs.
BarModule {
    id: root

    readonly property int secs: Math.ceil(S.Focus.remaining / 1000)
    readonly property string clock: `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, "0")}`

    tooltip: {
        if (!S.Focus.active)
            return `Start a ${S.Focus.workMinutes} min focus session (scroll to change)<br>Today: <b>${S.Focus.today}</b>`;
        const name = S.Focus.phase === "work" ? "Focus" : S.Focus.phase === "short" ? "Short break" : "Long break";
        return `${name}${S.Focus.paused ? " (paused)" : ""}: <b>${clock}</b><br>Session <b>${S.Focus.cycle}/${Theme.focusCycles}</b>, today: <b>${S.Focus.today}</b><br>Click to ${S.Focus.paused ? "resume" : "pause"}, right click to stop`;
    }
    onLeftClicked: S.Focus.toggle()
    onRightClicked: S.Focus.stop()
    onScrolledUp: S.Focus.adjust(5)
    onScrolledDown: S.Focus.adjust(-5)

    StyledText {
        color: !S.Focus.active ? Theme.fg : S.Focus.paused ? Theme.dim : S.Focus.phase === "work" ? Theme.accent : Theme.accent2
        text: {
            if (!S.Focus.active)
                return "\u{f051b}";
            const icon = S.Focus.paused ? "\u{f03e4}" : S.Focus.phase === "work" ? "\u{f051b}" : "\u{f0176}";
            return `${icon} ${root.clock}`;
        }
    }

    IdleInhibitor {
        window: root.QsWindow.window
        enabled: S.Focus.working
    }
}
