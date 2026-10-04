import QtQuick
import qs.components
import qs.config
import qs.services as S

// Small focus timer indicator (services/Focus.qml; the full timer is in the dashboard): only shown
// while a session runs, dimmed while paused. Click pauses or resumes, right click stops.
BarModule {
    id: root

    readonly property int secs: Math.ceil(S.Focus.remaining / 1000)

    visible: S.Focus.active
    tooltip: {
        const name = S.Focus.phase === "work" ? "Focus" : S.Focus.phase === "short" ? "Short break" : "Long break";
        const clock = `${Math.floor(secs / 60)}:${String(secs % 60).padStart(2, "0")}`;
        return `${name}${S.Focus.paused ? " (paused)" : ""}: <b>${clock}</b><br>Click to ${S.Focus.paused ? "resume" : "pause"}, right click to stop`;
    }
    onLeftClicked: S.Focus.toggle()
    onRightClicked: S.Focus.stop()

    StyledText {
        color: S.Focus.paused ? Theme.dim : S.Focus.phase === "work" ? Theme.accent : Theme.accent2
        text: S.Focus.paused ? "\u{f03e4}" : S.Focus.phase === "work" ? "\u{f051b}" : "\u{f0176}"
    }
}
