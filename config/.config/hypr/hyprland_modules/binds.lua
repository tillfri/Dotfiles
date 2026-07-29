-- Core keybinds
-- see https://wiki.hypr.land/Configuring/Basics/Binds/
-- and https://wiki.hypr.land/Configuring/Basics/Dispatchers/
-- (rewritten from the bind=/binde=/bindm= lines in hyprland.conf)

require("hyprland_modules/media-binds")

hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty")) -- open the terminal
hl.bind("SUPER + Q", hl.dsp.window.close()) -- close the active window
hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("sh -c '(sleep 0.5s; wlogout --protocol layer-shell)'"))
-- hl.bind("SUPER + ESCAPE", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + M", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume --toggle-sink"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("kitty yazi")) -- Show the graphical file browser
hl.bind("SUPER + V", hl.dsp.window.float()) -- Allow a window to float
-- hl.bind("SUPER + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_internal_monitor"), { locked = true })
hl.bind("SUPER + D", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -')) -- take a screenshot
hl.bind("SUPER + X", hl.dsp.exec_cmd("cliphist list | wofi -d | cliphist decode | wl-copy")) -- open clipboard manager
hl.bind("SUPER + Y", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "maximized" })) -- switch to fullscreen with bar
hl.bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- switch to fullscreen
hl.bind("SUPER + B", hl.dsp.exec_cmd("blueman-manager"))
hl.bind("SUPER + O", hl.dsp.exec_cmd("obsidian"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("swaync-client -t"))
-- hl.bind("SUPER + code:48", hl.dsp.exec_cmd("~/.config/hypr/scripts/change_background.sh"))
-- hl.bind("SUPER + code:34", hl.dsp.exec_cmd("~/.config/hypr/scripts/turn_on_screen"))

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
-- hl.bind("SUPER + SHIFT + up", hl.dsp.exec_cmd("busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n -500"))
-- hl.bind("SUPER + SHIFT + down", hl.dsp.exec_cmd("busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n +500"))

-- Move workspace to monitor
hl.bind("SUPER + code:59", hl.dsp.exec_cmd("~/.config/hypr/scripts/move_current_workspace_to_monitor 0"))
hl.bind("SUPER + code:60", hl.dsp.exec_cmd("~/.config/hypr/scripts/move_current_workspace_to_monitor 1"))

-- Move focus with mainMod + arrow keys
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))

hl.bind("SUPER + CONTROL + H", hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + CONTROL + L", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + CONTROL + K", hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + CONTROL + J", hl.dsp.window.swap({ direction = "d" }))

hl.bind("SUPER + SHIFT + H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Switch workspaces with mainMod + [0-9], move active window to a
-- workspace with mainMod + SHIFT + [0-9]. Key "0" maps to workspace 10.
local workspace_keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
for i, key in ipairs(workspace_keys) do
	local workspace = tostring(i)
	hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
end
-- hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e-1", follow = true }))
-- hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "e+1", follow = true }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
