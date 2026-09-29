-- Media keys: volume / mic / keyboard & monitor brightness
-- see https://wiki.hypr.land/Configuring/Basics/Binds/#example-binds
-- (rewritten from media-binds.conf)
--
-- NOTE: these are plain binds (not `locked`), matching the original
-- config's behavior. If you want them to also work while the screen is
-- locked, add `{ locked = true }` as a 3rd arg to hl.bind() -- see the
-- "Media" example binds on the wiki.

local script = os.getenv("HOME") .. "/.config/hypr/scripts"
-- The Quickshell OSD (quickshell/bar/modules/osd) changes the value and shows it on the focused monitor.
local osd = "qs -c bar ipc call osd "

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osd .. "volumeUp"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osd .. "volumeDown"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osd .. "toggleMic"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osd .. "toggleMute"))

hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(script .. "/kb-brightness --dec"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(script .. "/kb-brightness --inc"))

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. "brightnessDown"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osd .. "brightnessUp"))
