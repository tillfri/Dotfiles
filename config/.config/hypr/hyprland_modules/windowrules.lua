-- Window rules & layer rules
-- see https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- (rewritten from the windowrule=/layerrule= lines in hyprland.conf)
--
-- NOTE: rules are evaluated top to bottom, order matters.
-- Some rules below were merged compared to the original .conf: the old
-- config declared `float on` for org.gnome.Calculator twice (once alone,
-- once alongside `match:float true`) -- that duplicate has been folded
-- into a single rule here with identical resulting behavior.

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
-- hl.window_rule({ match = { class = "^(kitty)$" }, float = true })
-- hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
-- hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
-- hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
-- hl.window_rule({ match = { class = "^(chromium)$" }, float = true })
-- hl.window_rule({ match = { class = "^(thunar)$" }, float = true })
-- hl.window_rule({ match = { title = "^(btop)$" }, float = true })
-- hl.window_rule({ match = { title = "^(update-sys)$" }, float = true })
-- hl.window_rule({ match = { class = "^.*jetbrains-toolbox.*$" }, float = true })
-- hl.window_rule({ match = { class = "^(wofi)$" }, no_anim = true })
-- hl.window_rule({ match = { class = "^(wofi)$" }, opacity = "0.8 0.6" })

-- Rofi - smooth fade-in to hide background loading flash
-- hl.window_rule({ match = { class = "^(rofi)$" }, animation = "popin 60%" })

hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })

hl.window_rule({
	match = { class = "^(org.gnome.Calculator)$" },
	float = true,
	workspace = "special:scratchpad",
})

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/ for more
hl.window_rule({ match = { class = "^(thunar)$" }, opacity = "0.8 0.8" })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" }, opacity = "0.8 0.8" })
hl.window_rule({ match = { class = "^(VSCodium)$" }, opacity = "0.8 0.8" })
hl.window_rule({ match = { class = "^(obsidian)$" }, opacity = "0.8 0.8", workspace = "1" })
hl.window_rule({ match = { class = "^(Spotify)$" }, opacity = "0.8 0.8", workspace = "1" })
hl.window_rule({ match = { class = "^(discord)$" }, opacity = "0.8 0.8", workspace = "1" })
hl.window_rule({ match = { class = "^(kitty)$" }, opacity = "1.0" })
hl.window_rule({ match = { class = "^(ghostty)$" }, opacity = "1.0" })

hl.window_rule({ match = { class = "^(steam)$" }, float = true })

-- Layer rules
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, animation = "slide", ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true, animation = "fade" })
hl.layer_rule({ match = { namespace = "wofi" }, animation = "slide down", blur = true })
hl.layer_rule({
	match = { namespace = "swaync-notification-window" },
	blur = true,
	animation = "slide right",
	ignore_alpha = 0.5,
})
hl.layer_rule({
	match = { namespace = "swaync-control-center" },
	blur = true,
	animation = "slide right",
	ignore_alpha = 0.5,
})

-- Discord screen-sharing
hl.window_rule({
	match = { class = "^(xwaylandvideobridge)$" },
	opacity = "0.0 override",
	no_anim = true,
	no_initial_focus = true,
	no_blur = true,
	no_focus = true,
})
