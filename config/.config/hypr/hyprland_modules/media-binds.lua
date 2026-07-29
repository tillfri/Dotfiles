-- Media keys: volume / mic / keyboard & monitor brightness
-- see https://wiki.hypr.land/Configuring/Basics/Binds/#example-binds
-- (rewritten from media-binds.conf)
--
-- NOTE: these are plain binds (not `locked`), matching the original
-- config's behavior. If you want them to also work while the screen is
-- locked, add `{ locked = true }` as a 3rd arg to hl.bind() -- see the
-- "Media" example binds on the wiki.

local script = os.getenv("HOME") .. "/.config/hypr/scripts"
local focused_monitor = "$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')"

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd('swayosd-client --output-volume raise --monitor "' .. focused_monitor .. '"'))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd('swayosd-client --output-volume lower --monitor "' .. focused_monitor .. '"'))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(script .. "/volume --toggle-mic"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(script .. "/volume --toggle"))

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(script .. "/kb-brightness --dec"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(script .. "/kb-brightness --inc"))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd('swayosd-client --brightness lower --monitor "' .. focused_monitor .. '"'))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd('swayosd-client --brightness raise --monitor "' .. focused_monitor .. '"'))
