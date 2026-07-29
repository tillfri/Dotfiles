-- Workspace rules
-- see https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- (rewritten from the `workspace = ...` / `windowrule = border_size 0, ...`
-- lines in hyprland.conf)

-- No shadow on special (scratchpad) workspaces.
-- `no_shadow` is a workspace_rule field (see Rules table on the wiki page).
hl.workspace_rule({ workspace = "s[true]", no_shadow = true })

-- No blur for windows while on a special workspace.
-- (workspace_rule has no "blur" field; this is a per-window dynamic
-- effect instead, matched via the workspace prop.)
hl.window_rule({ match = { workspace = "s[true]" }, no_blur = true })

-- Smart gaps: no border when there's only one tiled window on a
-- workspace, or the workspace is fullscreened.
-- see https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/#smart-gaps
hl.window_rule({ match = { workspace = "w[tv1]s[true]" }, border_size = 0 })
hl.window_rule({ match = { workspace = "f[1]s[true]" }, border_size = 0 })
