local gpu_adapters = require('utils.gpu-adapter')
-- local backdrops = require('utils.backdrops')
-- local colors = require('colors.custom')

return {
   max_fps = 120,
   front_end = 'WebGpu',
   webgpu_power_preference = 'HighPerformance',
   webgpu_preferred_adapter = gpu_adapters:pick_best(),
   -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Dx12', 'IntegratedGpu'),
   -- webgpu_preferred_adapter = gpu_adapters:pick_manual('Gl', 'Other'),
   underline_thickness = '1.5pt',

   -- cursor
   animation_fps = 120,
   cursor_blink_ease_in = 'Linear',
   cursor_blink_ease_out = 'Linear',
   default_cursor_style = 'BlinkingBar',
   cursor_blink_rate = 900,

   -- color scheme
   -- colors = colors,
   color_scheme = 'Catppuccin Mocha',

   colors = {
      tab_bar = {
         background = 'rgba(30, 30, 46, 0.0)', --'#1e1e2e',
      },
   },
   -- background
   -- background = backdrops:initial_options(false), -- set to true if you want wezterm to start on focus mode
   background = {
      {
         source = { Color = '#1e1e2e' }, -- Set your desired background color
         height = '120%',
         width = '120%',
         vertical_offset = '-10%',
         horizontal_offset = '-10%',
         opacity = 0.8, -- Adjust transparency as needed
      },
   },

   -- window_background_opacity = 0.1,
   -- scrollbar
   enable_scroll_bar = true,

   -- tab bar
   enable_tab_bar = true,
   hide_tab_bar_if_only_one_tab = true,
   use_fancy_tab_bar = false,
   tab_max_width = 25,
   show_tab_index_in_tab_bar = true,
   show_new_tab_button_in_tab_bar = false,
   switch_to_last_active_tab_when_closing_tab = true,

   -- window
   window_padding = {
      left = 1,
      right = 2,
      top = 0,
      bottom = 0,
   },
   adjust_window_size_when_changing_font_size = false,
   window_close_confirmation = 'NeverPrompt',
   -- window_frame = {
   --    active_titlebar_bg = '#090909',
   --    -- font = fonts.font,
   --    -- font_size = fonts.font_size,
   -- },
   -- inactive_pane_hsb = {
   --    saturation = 0.9,
   --    brightness = 0.65,
   -- },
   inactive_pane_hsb = {
      saturation = 1,
      brightness = 1,
   },

   visual_bell = {
      fade_in_function = 'EaseIn',
      fade_in_duration_ms = 250,
      fade_out_function = 'EaseOut',
      fade_out_duration_ms = 250,
      target = 'CursorColor',
   },
}
