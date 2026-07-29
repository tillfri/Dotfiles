# Hyprland config: hyprlang (.conf) → Lua (.lua)

Since Hyprland 0.55, the `hyprlang` config syntax (`hyprland.conf`) is
deprecated in favor of a Lua-based config (`hyprland.lua`). This file
documents the new syntax for anyone (human or agent) editing this config,
based on https://wiki.hypr.land/Configuring/Basics/.

The old `hyprland.conf`, `thinkpad.conf`, `desktop.conf`, `media-binds.conf`
and `env_var.conf` files are kept in this directory as reference/fallback,
but the live config is `hyprland.lua` + `hyprland_modules/*.lua`.

## Entry point & module loading

Hyprland loads `~/.config/hypr/hyprland.lua` (or the path pointed to by the
`HYPRLAND_CONFIG` env var). Split-out config lives under
`hyprland_modules/` and is pulled in with Lua's `require()`, resolved
relative to `$XDG_CONFIG_HOME/hypr/` and **without** the `.lua` suffix:

```lua
-- refers to $XDG_CONFIG_HOME/hypr/hyprland_modules/keybinds.lua
require("hyprland_modules/keybinds")
```

Order matters only when two modules set the *same* key — the later
`require()` / `hl.config()` call wins. In this config, machine-specific
modules (`hyprland_modules/machine.lua`, symlinked to `desktop.lua` or
`thinkpad.lua`) are loaded **last** so they can override shared defaults
(gaps, shadows, monitors, extra binds).

## Variables — `hl.config()`

All the old top-level keywords/blocks (`general {}`, `decoration {}`,
`animations {}`, `input {}`, `misc {}`, `cursor {}`, `dwindle {}`,
`gestures {}`, `xwayland {}`, ...) become a single nested table passed to
`hl.config()`:

```lua
hl.config({
   category = {
       value = ...
   },
   category2 = {
       value2 = ...
   }
})
```

You can call `hl.config()` as many times as you like; each call only
updates the keys you pass in — it's safe to spread config across modules
and call it again later (e.g. inside a function) to change a value at
runtime.

Subcategories use dotted paths in the docs (e.g. `decoration.blur.*`) but
nested tables in Lua:

```lua
hl.config({
  decoration = {
    blur = { enabled = false },
    shadow = { enabled = false },
  }
})
```

### Value types
- `int`, `bool`, `float`, `str` — as expected.
- `color` — `"#rrggbb"`/`"#rrggbbaa"`, `"rgb(...)"`, `"rgba(...)"` (hex,
  no spaces), or legacy `0xaarrggbb`.
- `gradient` — a color, or `{ colors = {"rgba(...)", "rgba(...)"}, angle? = 45 }`.
- `vec2` — `{ x, y }`, e.g. `{ 20, 20 }`.
- `css_gaps` — an int, or `{ top?, left?, right?, bottom? }`.

## Monitors — `hl.monitor()`

```lua
hl.monitor({
  output = "DP-1",
  mode = "1920x1080@144",
  position = "0x0",
  scale = 1,
})
```
- `mode` specials: `"preferred"`, `"highres"`, `"highrr"`, `"maxwidth"`.
- `position` specials: `"auto"`, `"auto-right/left/up/down"`,
  `"auto-center-right/left/up/down"`.
- Leaving `output` empty defines a fallback rule for unmatched monitors.
- Y axis is inverted: negative Y = higher up, positive Y = lower down.

## Per-device input — `hl.device()`

For per-device overrides (e.g. a specific touchpad), use `hl.device()`
instead of the old `device { name = ... }` block:

```lua
hl.device({
    name = "etps/2-elantech-touchpad", -- from `hyprctl devices`
    sensitivity = 0,
    accel_profile = "adaptive",
})
```
Accepts anything from `input.*`/`input.touchpad.*`/etc. **except**
`force_no_accel` and window-management options (`follow_mouse`, etc).
Extra per-device-only fields: `enabled`, `keybinds`, `tags`.

## Binds — `hl.bind()` / `hl.unbind()`

```lua
hl.bind(keys, dispatcher)
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("firefox"))
hl.unbind("SUPER + O")
```

- `keys` is a `"MOD + MOD + key"` string. Use `code:NN` for keycodes,
  `mouse:NNN` for mouse buttons, `mouse_up`/`mouse_down`/`mouse_left`/
  `mouse_right` for wheel, `switch:[name]` / `switch:on:[name]` /
  `switch:off:[name]` for lid/tablet switches.
- `dispatcher` comes from `hl.dsp.*` (see below), or a plain Lua function
  for multi-step / conditional binds:
  ```lua
  hl.bind("SUPER + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next())
      hl.dispatch(hl.dsp.window.bring_to_top())
  end)
  ```
- Optional 3rd arg is a flags table: `hl.bind(keys, dispatcher, { repeating = true, locked = true, release = true, description = "...", device = { inclusive = true, list = {"dev1"} } })`.
  Common flags: `locked`, `release`, `click`, `drag`, `long_press`,
  `repeating`, `non_consuming`, `auto_consuming`, `transparent`,
  `ignore_mods`, `description`, `device`.
- Global (all-apps, incl. XWayland/Electron) keybinds: `hl.dsp.pass({ window = "class:^(...)$" })`
  or `hl.dsp.send_shortcut({ mods=, key=, window= })`.
- DBus global shortcuts (via xdg-desktop-portal-hyprland): `hl.dsp.global("app:shortcutName")`.
- Submaps: `hl.bind(keys, hl.dsp.submap("name"))` + `hl.define_submap("name", function() ... end)`.

## Dispatchers — `hl.dsp.*`

Dispatchers build a table describing an action; they don't run it
directly. Feed them into `hl.bind()`, or call `hl.dispatch(...)` yourself
inside a function bind.

Namespaces: `hl.dsp.*` (general: `exec_cmd`, `focus`, `submap`, `pass`,
`send_shortcut`, `layout`, `dpms`, `global`, `event`, `exit`, ...),
`hl.dsp.window.*` (`close`, `kill`, `float`, `fullscreen`, `move`, `swap`,
`center`, `pin`, `resize`, `deny_from_group`, ...),
`hl.dsp.workspace.*` (`rename`, `move`, `swap_monitors`,
`toggle_special`), `hl.dsp.group.*`, `hl.dsp.cursor.*`.

`exec_cmd(cmd, rules?)` can apply window-rule-like effects to the window
the command opens: `hl.dsp.exec_cmd("kitty", { float = true, move = {0,0} })`.

Workspace selector strings (used all over: binds, window rules, workspace
rules): ID (`"3"`), relative (`"+1"`, `"-2"`), on-monitor (`"m+1"`,
`"m~3"`), on-monitor-incl-empty (`"r+1"`), open workspaces (`"e+1"`,
`"e-10"`), name (`"name:Web"`), `"previous"`, `"empty"` (+ `m`/`n`
suffixes), `"special"` / `"special:name"`.

> **Note:** avoid the `exit` dispatcher directly if using uwsm — prefer
> `hl.dsp.exec_cmd("uwsm stop")`.

## Window rules — `hl.window_rule()`

```lua
hl.window_rule({
  name = "apply-something", -- optional; anonymous rules are fine too
  match = {
    class = "my-window",   -- RegEx (RE2). Prefix "negative:" to invert.
  },
  border_size = 10,        -- one or more "effects"
})
```

- Rules are evaluated **top to bottom** — order matters.
- `match` fields ("props"): `class`, `title`, `initial_class`,
  `initial_title`, `tag`, `xwayland`, `float`, `fullscreen`, `pin`,
  `focus`, `group`, `modal`, `fullscreen_state_client`,
  `fullscreen_state_internal`, `workspace`, `content`, `xdg_tag`. At
  least one prop is required; each prop can only appear once per rule.
- **Static effects** (evaluated once at window open, so `class`/`title`
  matching here always sees the *initial* values): `float`, `tile`,
  `fullscreen`, `maximize`, `fullscreen_state`, `move`, `size`, `center`,
  `pseudo`, `monitor`, `workspace`, `no_initial_focus`, `pin`, `group`,
  `suppress_event`, `content`, `no_close_for`, `scrolling_width`.
- **Dynamic effects** (re-evaluated on every property change):
  `persistent_size`, `no_max_size`, `stay_focused`, `animation`,
  `border_color`, `idle_inhibit`, `opacity`, `tag`, `max_size`,
  `min_size`, `border_size`, `rounding`, `rounding_power`,
  `allows_input`, `dim_around`, `decorate`, `focus_on_activate`,
  `keep_aspect_ratio`, `nearest_neighbor`, `no_anim`, `no_blur`, `no_dim`,
  `no_focus`, `no_follow_mouse`, `no_shadow`, `no_shortcuts_inhibit`.
- `move`/`size` accept expressions using `monitor_w/h`, `window_x/y/w/h`,
  `cursor_x/y`, e.g. `move = {"window_w * 0.5", "(monitor_h/2)+17"}`.
- A named rule returns a handle: `rule:set_enabled(false)` /
  `rule:is_enabled()`.

## Layer rules — `hl.layer_rule()`

Same shape as window rules, for non-window layer-shell surfaces
(status bars, launchers, wallpapers, notifications):

```lua
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })
```
Match field: `namespace` (RegEx, check with `hyprctl layers`). Effects:
`no_anim`, `blur`, `blur_popups`, `ignore_alpha`, `dim_around`, `xray`,
`animation`, `order`, `above_lock`, `no_screen_share`.

## Workspace rules — `hl.workspace_rule()`

```lua
hl.workspace_rule({ workspace = "3", no_rounding = true, decorate = false })
hl.workspace_rule({ workspace = "name:coding", monitor = "DP-1", default = true })
```
`workspace` (mandatory) takes a workspace selector, or an *existing*-only
workspace *selector expression* like `w[tv1]` / `s[true]` / `r[2-4]` /
`f[1]` (see wiki for the full prop list: `r[A-B]`, `s[bool]`, `n[...]`,
`m[monitor]`, `w[(flags)A-B]`, `f[-1|0|1|2]`). Other fields: `monitor`,
`default`, `gaps_in`, `gaps_out`, `float_gaps`, `border_size`,
`no_border`, `no_shadow`, `no_rounding`, `decorate`, `persistent`,
`on_created_empty`, `default_name`, `layout`, `animation`, `layout_opts`.

"Smart gaps" (no gaps/border/rounding when only one window) pattern:
```lua
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
```

## Autostart — `hl.on("hyprland.start", ...)`

Replaces `exec-once =`. Fires once, at startup:

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("hyprpaper")
end)
```
`hl.exec_cmd()` spawns async — no need for `& disown`. Mirror with
`hl.on("hyprland.shutdown", function() ... end)` for cleanup on exit.

> Note: the old config had one plain `exec = wl-paste --watch cliphist
> store` (no `-once`), which technically re-ran on every config reload.
> There's no direct Lua equivalent of that repeat-on-reload behavior —
> it's folded into `hyprland.start` here like the rest of autostart,
> which only runs once per session (arguably the intended behavior
> anyway).

## Environment variables — `hl.env()`

Replaces `env = KEY,VALUE`. Must be set before the display server inits:

```lua
hl.env("XCURSOR_SIZE", "24")
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
```
Use `os.getenv()` to reference existing env vars — don't hardcode paths.
Hyprland-specific: `HYPRLAND_TRACE`, `HYPRLAND_NO_RT`,
`HYPRLAND_NO_SD_NOTIFY`, `HYPRLAND_NO_SD_VARS`, `HYPRLAND_CONFIG`.

> Avoid `/etc/environment` for Wayland-only vars — it leaks into Xorg
> sessions too. If using uwsm, prefer `~/.config/uwsm/env` /
> `~/.config/uwsm/env-hyprland` instead of `hl.env()` for most vars.

## Old → new quick reference

| hyprlang (.conf)                          | Lua (.lua)                                        |
|--------------------------------------------|----------------------------------------------------|
| `source = path.conf`                       | `require("hyprland_modules/name")`                  |
| `monitor = DP-1,1920x1080@144,0x0,1`       | `hl.monitor({ output=, mode=, position=, scale= })` |
| `general { ... }` / `decoration { ... }` / any `category { key = val }` | `hl.config({ category = { key = val } })` |
| `device { name = ...; ... }`               | `hl.device({ name = ..., ... })`                    |
| `bind = MODS, KEY, dispatcher, args`       | `hl.bind("MODS + KEY", hl.dsp.dispatcher(args))`    |
| `bindm = ...` (mouse move/resize binds)    | `hl.bind("MODS + mouse:NNN", hl.dsp.window.drag())` / `resize()` |
| `windowrule = effect, match`               | `hl.window_rule({ match = {...}, effect = val })`   |
| `layerrule = effect, namespace`            | `hl.layer_rule({ match = { namespace=... }, effect = val })` |
| `workspace = SELECTOR, rule:val`           | `hl.workspace_rule({ workspace = SELECTOR, rule = val })` |
| `exec-once = cmd`                          | `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` |
| `env = KEY,VALUE`                          | `hl.env("KEY", "VALUE")`                            |
| `$VAR = value` (config-time variable)      | plain Lua `local var = "value"`                     |

## Module layout in this config

```
hyprland.lua                        -- entry point, require()s everything below
hyprland_modules/
  env.lua                           -- hl.env() calls (from env_var.conf)
  autostart.lua                     -- hl.on("hyprland.start", ...) (from exec-once lines)
  general.lua                       -- general/misc/cursor/decoration/animations/dwindle/gestures/xwayland
  input.lua                         -- input {} + per-device touchpad override
  windowrules.lua                   -- hl.window_rule() / hl.layer_rule()
  workspacerules.lua                -- hl.workspace_rule() (incl. smart-gaps-on-special)
  binds.lua                         -- core keybinds, requires media-binds.lua
  media-binds.lua                   -- volume/brightness/mic media keys
  desktop.lua                       -- desktop-only: monitors, kb layout, gaps, shadow, binds
  thinkpad.lua                      -- thinkpad-only: monitor, kb layout, gaps, shadow,
                                        binds, + blur/shadow disabled for battery life
  machine.lua                       -- symlink -> desktop.lua or thinkpad.lua (like old machine.conf)
```

The legacy `hyprland.conf` / `thinkpad.conf` / `desktop.conf` /
`media-binds.conf` / `env_var.conf` files are left in place as a
reference/fallback and are **not** loaded by `hyprland.lua`.
`env_var_nvidia.conf` and `rog-g15-strix-2021-binds.conf` were already
unused before this rewrite and remain untouched.
