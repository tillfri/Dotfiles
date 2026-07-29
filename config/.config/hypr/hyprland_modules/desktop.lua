-- Desktop-specific configuration
-- (rewritten from desktop.conf; loaded via hyprland_modules/machine.lua symlink)

-- Monitors
hl.monitor({ output = "DP-2", mode = "3840x2160@160", position = "0x0", scale = 1.5 })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "2560x0", scale = 1 })

-- Environment variables
hl.env("XDG_MENU_PREFIX", "arch-")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "gtk3")

hl.config({
	-- Input
	input = {
		kb_layout = "us",
		kb_variant = "altgr-intl",
	},

	-- General
	general = {
		gaps_out = { top = 3, right = 10, bottom = 10, left = 10 },
	},

	-- Decoration
	decoration = {
		shadow = {
			range = 4,
		},
	},
})

-- Workspace settings
hl.workspace_rule({ workspace = "2", monitor = "DP-2" })
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "s[true]", gaps_out = 100, gaps_in = 0 })

-- Binds
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("ghostty")) -- open the terminal
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("pkill wofi || wofi")) -- Show the graphical app launcher
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture-menu")) -- Capture menu (screenshot, screenrecord, color picker)
