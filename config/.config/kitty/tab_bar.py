"""Custom tab bar helpers.

draw_title(data) backs the {custom} field of tab_title_template. It returns the
program status symbol (OSC 7501) with the static "working" glyph replaced by a
spinner frame. A repeating timer marks the tab bar dirty only while some window
is working, so kitty stays idle otherwise.
"""

import sys
from typing import Any

from kitty.fast_data_types import add_timer, get_boss, monotonic

FRAMES = '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
FRAME_INTERVAL = 0.1  # seconds
WORKING_GLYPH = ''  # what kitty uses for "working"


def _any_working() -> bool:
    from kitty.program_status import State

    boss = get_boss()
    for tm in boss.all_tab_managers:
        for tab in tm:
            for w in tab:
                r = w.program_status.most_urgent()
                if r is not None and r.state is State.working:
                    return True
    return False


def _tick(timer_id: int | None = None) -> None:
    try:
        if _any_working():
            for tm in get_boss().all_tab_managers:
                tm.mark_tab_bar_dirty()
    except Exception:
        pass


def _ensure_timer() -> None:
    # runpy re-executes this file on config reload; keep a single timer alive
    mod = sys.modules.get('kitty.tab_bar')
    if mod is None or getattr(mod, '_spinner_timer_started', False):
        return
    mod._spinner_timer_started = True  # type: ignore[attr-defined]
    add_timer(_tick, FRAME_INTERVAL, True)


def draw_title(data: dict[str, Any]) -> str:
    _ensure_timer()
    status: str = data['tab'].program_status
    if status.startswith(WORKING_GLYPH):
        frame = FRAMES[int(monotonic() / FRAME_INTERVAL) % len(FRAMES)]
        status = frame + status[len(WORKING_GLYPH):]
    return status
