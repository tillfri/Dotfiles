-- Input devices
-- see https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- and https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
-- (rewritten from the input{}/device{} blocks in hyprland.conf)

hl.config({
	input = {
		kb_model = "",
		kb_options = "",
		kb_rules = "",

		follow_mouse = 1,

		repeat_delay = 200,
		repeat_rate = 35,

		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.15,
		},

		accel_profile = "flat",
		sensitivity = 0,
	},
})

-- Per-device override for the internal touchpad (name from `hyprctl devices`)
hl.device({
	name = "etps/2-elantech-touchpad",
	sensitivity = 0,
	accel_profile = "adaptive",
})
