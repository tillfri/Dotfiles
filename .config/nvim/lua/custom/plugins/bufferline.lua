return {
  'akinsho/bufferline.nvim',
  dependencies = {
    'moll/vim-bbye',
    'nvim-tree/nvim-web-devicons',
    'catppuccin/nvim', -- Ensure catppuccin is loaded first
  },
  config = function()
    require('bufferline').setup {
      options = {
        mode = 'buffers', -- set to "tabs" to only show tabpages instead
        themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
        numbers = 'none', -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        close_command = 'Bdelete! %d', -- can be a string | function, see "Mouse actions"
        buffer_close_icon = '✗',
        close_icon = '✗',
        path_components = 1, -- Show only the file name without the directory
        modified_icon = '●',
        left_trunc_marker = '',
        right_trunc_marker = '',
        max_name_length = 60,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        tab_size = 30,
        truncate_names = true, -- truncate names that exceed max_name_length
        diagnostics = 'nvim_lsp',
        diagnostics_update_in_insert = false,
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
          if level:match 'error' then
            return ' ' .. diagnostics_dict.error
          end
          return ''
        end,
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        separator_style = { '│', '│' },
        enforce_regular_tabs = true,
        always_show_bufferline = true,
        show_tab_indicators = false,
        indicator = {
          -- icon = '▎', -- this should be omitted if indicator style is not 'icon'
          style = 'none', -- Options: 'icon', 'underline', 'none'
        },
        icon_pinned = '󰐃',
        minimum_padding = 1,
        maximum_padding = 5,
        maximum_length = 60,
        sort_by = 'insert_at_end',
      },
      highlights = {
        buffer_selected = {
          bold = true,
          italic = false,
        },
        error = {
          fg = {
            attribute = 'fg',
            highlight = 'DiagnosticError',
          },
        },
        error_visible = {
          fg = {
            attribute = 'fg',
            highlight = 'DiagnosticError',
          },
        },
        close_button_selected = {
          fg = {
            attribute = 'fg',
            highlight = 'DiagnosticError',
          },
        },
        warning_selected = {
          bold = true,
          italic = false,
        },
        info_selected = {
          bold = true,
          italic = false,
        },
        hint_selected = {
          bold = true,
          italic = false,
        },
      },
    }
  end,
}
