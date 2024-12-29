local wezterm = require 'wezterm'
local act = wezterm.action
if os.getenv("XDG_CURRENT_DESKTOP") == "Hyprland" then
	config.enable_wayland = false
else
	config.enable_wayland = true
end

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
    local zoomed = ''
    if tab.active_pane.is_zoomed then
      zoomed = '[Z] '
    end
  
    local index = ''
    if #tabs > 1 then
        -- Get the current user
        local username = os.getenv("USER") or os.getenv("USERNAME") or "unknown"

        -- Get the hostname
        local hostname = io.popen("hostname"):read("*l") or "unknown"

      index = string.format('%s@%s:', username, hostname)
    end
  
    return zoomed .. index .. tab.active_pane.title
  end)

function tab_title(tab_info)
    local title = tab_info.tab_title
    -- if the tab title is explicitly set, take that
    if title and #title > 0 then
      return title
    end
    -- Otherwise, use the title from the active pane
    -- in that tab
    return tab_info.active_pane.title
  end
  
  wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
    local title = tab_title(tab)
    local pane = tab.active_pane
    local active_symbol = "📁"  -- Default symbol for directory
  
    -- Check if the pane title contains 'nano' to change the symbol
    if pane.title:match("nano") or tab.active_pane.title:match("vi") then
      active_symbol = "✏️"  -- Symbol for editing with nano
    end
  
    if tab.is_active then
      return {
        { Background = { Color = '#7882d1' } },
        { Text = ' ' .. active_symbol .. ' ' .. title .. ' ' },
      }
    elseif hover then
      return {
        { Background = { Color = 'gray' } },
        { Text = ' 📂 ' .. title .. ' ' },
      }
    else
      return ' ' .. title .. ' '
    end
  end)
  

mb = {
}

for i = 1,99,1 
do 
  table.insert(mb,
  {
    event = { Down = { streak = i, button = 'Middle' } },
    mods = 'NONE',
    action = act.PasteFrom("PrimarySelection")
  })
  table.insert(mb, {
    event = { Down = { streak = i, button = 'Right' } },
       mods = 'NONE',
       action = wezterm.action_callback(function(window, pane)
         local has_selection = window:get_selection_text_for_pane(pane) ~= ''
         if has_selection then
           window:perform_action(
             act.CopyTo 'ClipboardAndPrimarySelection',
             pane
           )
   
           window:perform_action(act.ClearSelection, pane)
         else
           window:perform_action(act.PasteFrom("PrimarySelection"), pane)
         end
       end),
     })
end

return {
  disable_default_key_bindings = true,
  pane_focus_follows_mouse = false,
  mouse_bindings = mb,
  initial_cols = 160,
  initial_rows = 48,
  config.enable_wayland = false,
--  leader = { key = 'VoidSymbol', timeout_milliseconds = 1000 },
  keys = {
--    {
--      key = 'c',
--      mods = 'CTRL|SHIFT',
--      action = wezterm.action.SpawnCommandInNewTab {
--        args = { 'zsh' },
--        cwd = '~'
--      },
--    },
    {
      key = 'PageUp',
      mods = 'SHIFT',
      action = act.ScrollByPage(-1),
    },
    {
      key = 'x',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.CloseCurrentPane { confirm = true },
    },
    {
      key = 'PageDown',
      mods = 'SHIFT',
      action = act.ScrollByPage(1),
    },
    {
      key = 'v',
      mods = 'CTRL|SHIFT',
      action = act.PasteFrom("Clipboard"),
    },
    {
      key = 'c',
      mods = 'CTRL|SHIFT',
      action = act.CopyTo("Clipboard"),
    },
    {
      key = 't',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SpawnCommandInNewTab {
        args = { 'zsh' },
        cwd = '~'
      },
    },
    {
      key = 'f',
      mods = 'CTRL',
      action = wezterm.action.TogglePaneZoomState,
    },
    { key = 'f', mods = 'SHIFT|CTRL', action = act.Search 'CurrentSelectionOrEmptyString' },
    {
        key = 'r',
        mods = 'CTRL|SHIFT',
        action = wezterm.action.ReloadConfiguration,
    },
   
--    {
--      key = 'p',
--      mods = 'LEADER',
--      action = act.ActivateTabRelative(-1),
--    },
--    {
--      key = 'n',
--      mods = 'LEADER',
--      action = act.ActivateTabRelative(1),
--    },
    {
      key = 'Tab',
      mods = 'CTRL|SHIFT',
      action = act.ActivateTabRelative(-1),
    },
    {
      key = 'Tab',
      mods = 'CTRL',
      action = act.ActivateTabRelative(1),
    },
    {
        key = 'E',
        mods = 'CTRL|SHIFT',
        action = act.PromptInputLine {
          description = 'Enter new name for tab',
          action = wezterm.action_callback(function(window, pane, line)
            -- line will be `nil` if they hit escape without entering anything
            -- An empty string if they just hit enter
            -- Or the actual line of text they wrote
            if line then
              window:active_tab():set_title(line)
            end
          end),
        },
      },
    {
      key = '2',
      mods = 'CTRL',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = '2',
      mods = 'LEADER',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = '5',
      mods = 'CTRL',
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = '5',
      mods = 'LEADER',
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'LeftArrow',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Left',
    },
    {
      key = 'RightArrow',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Right',
    },
    {
      key = 'UpArrow',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Up',
    },
    {
      key = 'DownArrow',
      mods = 'CTRL',
      action = act.ActivatePaneDirection 'Down',
    }
  },
  key_tables = {
    copy_mode = {
      { key = 'Tab', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'Tab', mods = 'SHIFT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'MoveToStartOfNextLine' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'Space', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = '$', mods = 'SHIFT', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
      { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
      { key = 'F', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 'F', mods = 'SHIFT', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'G', mods = 'SHIFT', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'H', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
      { key = 'L', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportBottom' },
      { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'M', mods = 'SHIFT', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      { key = 'O', mods = 'SHIFT', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = 'T', mods = 'SHIFT', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = 'V', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Line' } },
      { key = 'V', mods = 'SHIFT', action = act.CopyMode{ SetSelectionMode =  'Line' } },
      { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = '^', mods = 'SHIFT', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'b', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
      { key = 'c', mods = 'CTRL', action = act.CopyMode 'Close' },
      { key = 'd', mods = 'CTRL', action = act.CopyMode{ MoveByPage = (0.5) } },
      { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },
      { key = 'f', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = false } } },
      { key = 'f', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
      { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
      { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
      { key = 'g', mods = 'CTRL', action = act.CopyMode 'Close' },
      { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'm', mods = 'ALT', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
      { key = 'q', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 't', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = true } } },
      { key = 'u', mods = 'CTRL', action = act.CopyMode{ MoveByPage = (-0.5) } },
      { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode =  'Cell' } },
      { key = 'v', mods = 'CTRL', action = act.CopyMode{ SetSelectionMode =  'Block' } },
      { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'y', mods = 'NONE', action = act.Multiple{ { CopyTo =  'ClipboardAndPrimarySelection' }, { CopyMode =  'Close' } } },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
      { key = 'End', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = 'Home', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'LeftArrow', mods = 'ALT', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'RightArrow', mods = 'ALT', action = act.CopyMode 'MoveForwardWord' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
    },

    search_mode = {
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
      { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
      { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
      { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
    },

  },
  window_padding = {
    left = 2,
    right = 2,
    top = 0,
    bottom = 0,
  },
  window_frame = {
    border_left_width = '0.5cell',
    border_right_width = '0.5cell',
    font = wezterm.font { family = 'Roboto', weight = 'Bold' },
    font_size = 12.0,
  },
  tab_bar_at_bottom = true,
  use_fancy_tab_bar = true,
  font =  wezterm.font_with_fallback({"JetBrainsMono Nerd Font Mono", "Courier 10 Pitch"}),
  font_size = 12,
  enable_scroll_bar = true,
  show_tab_index_in_tab_bar = false,
  animation_fps = 60,
  color_scheme = "CustomScheme",
  color_schemes = {
    ["CustomScheme"] = {
      foreground = "#FFFFFF",          -- [Foreground]
      background = "#19191f",          -- [Background]
      cursor_bg = "#CCCCCC",           -- Default cursor color
      cursor_border = "#CCCCCC",       -- Cursor border color
      cursor_fg = "#131316",           -- Text color when cursor is inverted

      selection_fg = "#131316",        -- Text color when selected
      selection_bg = "#FFFFFF",        -- Background color when selected

      ansi = {
        "#232627",  -- [Color0]
        "#ED1515",  -- [Color1]
        "#11D116",  -- [Color2]
        "#F67400",  -- [Color3]
        "#1D99F3",  -- [Color4]
        "#9B59B6",  -- [Color5]
        "#1ABC9C",  -- [Color6]
        "#FCFCFC",  -- [Color7]
      },
      brights = {
        "#D87700",  -- [Color0Intense]
        "#C0392B",  -- [Color1Intense]
        "#1CDC9A",  -- [Color2Intense]
        "#FDBC4B",  -- [Color3Intense]
        "#3DAEE9",  -- [Color4Intense]
        "#8E44AD",  -- [Color5Intense]
        "#16A085",  -- [Color6Intense]
        "#FFFFFF",  -- [Color7Intense]
      },

      indexed = {
        [16] = "#31363B", -- [BackgroundFaint]
        [17] = "#FFCC00", -- Any other extra color you may want to add (optional)
      },

      tab_bar = {
        background = "#131316", -- Tab bar background color
        active_tab = {
          bg_color = "#31363B", -- Active tab background color
          fg_color = "#FFFFFF", -- Active tab foreground color
        },
        inactive_tab = {
          bg_color = "#232627", -- Inactive tab background color
          fg_color = "#C0C0C0", -- Inactive tab foreground color
        },
        inactive_tab_hover = {
          bg_color = "#3D3F43", -- Inactive tab hover background color
          fg_color = "#D0D0D0", -- Inactive tab hover foreground color
        },
        new_tab = {
          bg_color = "#131316", -- New tab button background color
          fg_color = "#FFFFFF", -- New tab button foreground color
        },
        new_tab_hover = {
          bg_color = "#3D3F43", -- New tab hover background color
          fg_color = "#D0D0D0", -- New tab hover foreground color
        },
      },
    }
  },
}
