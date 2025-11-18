from kittens.tui.handler import result_handler
from kitty.boss import Boss


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss: Boss):
    import kitty.fast_data_types as f

    os_window_id = f.current_focused_os_window_id()
    current_opacity = f.background_opacity_of(os_window_id)
    # Toggle between 0.8 and 1.0
    new_opacity = "1.0" if current_opacity < 0.9 else "0.8"
    boss.set_background_opacity(new_opacity)
