-- Hyprland config entry point (Lua syntax, Hyprland >= 0.55)
-- See AGENTS.md in this directory for a syntax primer / old->new mapping.
--
-- This replaces hyprland.conf. The legacy .conf files are kept in this
-- directory as reference/fallback but are no longer sourced.

require("hyprland_modules/env")
require("hyprland_modules/general")
require("hyprland_modules/input")
require("hyprland_modules/windowrules")
require("hyprland_modules/workspacerules")
require("hyprland_modules/binds")
require("hyprland_modules/autostart")

-- Machine-specific overrides (monitors, gaps, shadows, extra binds).
-- Loaded last so it can override the shared defaults above.
-- hyprland_modules/machine.lua is a symlink -> desktop.lua or thinkpad.lua,
-- mirroring the old machine.conf convention:
--   ln -sf desktop.lua ~/.config/hypr/hyprland_modules/machine.lua
--   ln -sf thinkpad.lua ~/.config/hypr/hyprland_modules/machine.lua
require("hyprland_modules/machine")
