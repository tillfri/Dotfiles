-- ThinkPad-specific configuration
-- (rewritten from thinkpad.conf; loaded via hyprland_modules/machine.lua symlink)

-- Monitors
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = 1.2 })

hl.config({
	-- Input
	input = {
		kb_layout = "de",
	},

	-- General
	general = {
		gaps_out = { top = 7, right = 10, bottom = 10, left = 10 },
	},

	-- Decoration
	decoration = {
		shadow = {
			range = 2,
			color = "rgba(1a1a1aee)",
		},
	},
})

-- Disable fancy but battery-hungry effects on the go (blur + shadows).
-- Kept as separate hl.config() calls per the AGENTS.md convention: safe to
-- call multiple times, each call only updates the keys passed in.
hl.config({ decoration = { blur = { enabled = false } } })
hl.config({ decoration = { shadow = { enabled = false } } })

-- Workspace settings
hl.workspace_rule({ workspace = "s[true]", gaps_out = 50, gaps_in = 0 })

-- Binds
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("pkill wofi || wofi")) -- Show the graphical app launcher
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture-menu")) -- Capture menu (screenshot, screenrecord, color picker)
