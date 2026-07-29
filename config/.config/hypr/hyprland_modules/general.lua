-- General config: xwayland, general, misc, cursor, decoration, animations,
-- dwindle, gestures.
-- see https://wiki.hypr.land/Configuring/Basics/Variables/
-- and https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- (rewritten from the xwayland{}/general{}/misc{}/cursor{}/decoration{}/
-- animations{}/dwindle{}/gestures{} blocks in hyprland.conf)

-- Combat blurry fonts on Xorg programs
hl.config({
	xwayland = {
		force_zero_scaling = true,
	},

	general = {
		gaps_in = 3,
		border_size = 2,
		["col.active_border"] = "rgba(FFFFFFaa)",
		-- ["col.active_border"] = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
		["col.inactive_border"] = "rgba(5959595a)",
		layout = "dwindle",
		resize_on_border = true, -- Allow resizing windows by dragging their borders
		allow_tearing = false, -- Disable screen tearing during window resizing and movements
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		-- new_window_takes_over_fullscreen = 2,
	},

	cursor = {
		-- hide_on_key_press = true,
		warp_on_change_workspace = 1,
		inactive_timeout = 2,
	},

	decoration = {
		rounding = 6,

		blur = {
			enabled = true,
			size = 4,
			passes = 3,
			special = true,
			brightness = 0.7,
			contrast = 0.8,
		},

		shadow = {
			enabled = true,
			render_power = 3,
		},

		-- glow = { enabled = true },
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		preserve_split = true, -- you probably want this
	},
})

-- gestures {}
-- NOTE: the old config had `workspace = no` here, which was a legacy/
-- deprecated key from before the current gestures system (see
-- workspace_swipe_* in Variables#gestures). It has no direct modern
-- equivalent and was already a no-op (touch workspace swiping is off by
-- default), so it is intentionally not carried over. Use hl.gesture({...})
-- if you want touch/touchpad swipe gestures.

-- Beziers (curve name, control points)
-- see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/#curves
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("myBezier", { type = "bezier", points = { { 0.10, 0.9 }, { 0.1, 1.05 } } })
hl.curve("easeOutExpo", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })

-- Animations (leaf, enabled, speed in ds, curve, style?)
-- see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/#animation-tree
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "easeOutQuint", style = "slidevert" })
