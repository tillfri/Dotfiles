-- Autostart
-- see https://wiki.hypr.land/Configuring/Basics/Autostart/
-- (rewritten from the exec-once / exec lines in hyprland.conf)
--
-- Note: the old config had one plain `exec = wl-paste --watch cliphist
-- store` (no `-once`), which in hyprlang re-runs on every config reload.
-- hl.on("hyprland.start", ...) only fires once per session, so this is
-- folded in here like the rest of autostart (arguably the intended
-- behavior anyway -- see AGENTS.md).

hl.on("hyprland.start", function()
	hl.exec_cmd("~/.config/hypr/xdg-portal-hyprland")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	-- NOTE: "--no-startup-id" is carried over verbatim from the original
	-- exec-once line; it is not a real flag for gnome-keyring-daemon and
	-- looks like a leftover from an i3/openbox config. Kept as-is for
	-- behavioral parity -- consider dropping it.
	hl.exec_cmd("--no-startup-id /usr/bin/gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("xwaylandvideobridge")
	hl.exec_cmd("waybar")
	hl.exec_cmd("hypridle")
	-- Notification Daemon
	-- hl.exec_cmd("swaync")
	-- Bluetooth
	hl.exec_cmd("blueman-applet")
	-- NetworkManager
	hl.exec_cmd("nm-applet --indicator")
	-- Copy-Paste
	hl.exec_cmd("wl-paste --watch cliphist store")
	-- Blue Light Filter
	hl.exec_cmd("hyprsunset")
	-- Automount usb drives when plugged in
	hl.exec_cmd("udiskie")
	-- Phone
	hl.exec_cmd("/usr/bin/kdeconnectd")
	hl.exec_cmd("/usr/bin/kdeconnect-indicator")
	-- OSD for Volume/Brightness
	hl.exec_cmd("swayosd-server")
end)
