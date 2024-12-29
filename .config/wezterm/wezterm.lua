local wezterm = require 'wezterm'
local act = wezterm.action

wezterm.on('format-window-title', function(tab)
    local zoomed = tab.active_pane.is_zoomed and "[Z] " or ""
    local username = os.getenv("USER") or "unknown"
    local hostname = os.getenv("HOSTNAME") or "unknown"
    local index = (#tab.tabs > 1) and string.format('%s@%s:', username, hostname) or ""
    return zoomed .. index .. tab.active_pane.title
end)

wezterm.on('format-tab-title', function(tab)
    local title = tab.active_pane.title
    local symbol = title:match("nano") and "✏️" or "📁"
    if tab.is_active then
        return {{Background = {Color = '#7882d1'}}, {Text = ' ' .. symbol .. ' ' .. title .. ' '}}
    end
    return ' ' .. title .. ' '
end)

return {
    enable_wayland = false,
    mouse_bindings = {
        {event = {Down = {button = 'Middle'}}, mods = 'NONE', action = act.PasteFrom("PrimarySelection")},
        {event = {Down = {button = 'Right'}}, mods = 'NONE', action = wezterm.action_callback(function(window, pane)
            if window:get_selection_text_for_pane(pane) ~= '' then
                window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.PasteFrom("PrimarySelection"), pane)
            end
        end)},
    },
    keys = {
        {key = 'c', mods = 'CTRL|SHIFT', action = act.CopyTo("Clipboard")},
        {key = 'v', mods = 'CTRL|SHIFT', action = act.PasteFrom("Clipboard")},
        -- More keybindings...
    },
    font = wezterm.font_with_fallback({"JetBrainsMono Nerd Font Mono", "Courier 10 Pitch", "monospace"}),
    font_size = 12,
    color_scheme = "CustomScheme",
    color_schemes = {
        ["CustomScheme"] = {
            foreground = "#E0E0E0",
            background = "#19191f",
            -- More color configs...
        },
    },
}
