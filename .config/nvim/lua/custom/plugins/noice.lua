return {
  'folke/noice.nvim',
  config = function()
    -- Create autocmd for macro recording
    local macro_group = vim.api.nvim_create_augroup('MacroRecording', { clear = true })
    vim.api.nvim_create_autocmd('RecordingLeave', {
      group = macro_group,
      callback = function()
        -- Display a message when macro recording stops
        print 'Macro recording stopped'
      end,
    })

    require('noice').setup {
      lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
        },
      },
      routes = {
        {
          filter = {
            event = 'msg_show',
            any = {
              { find = '%d+L, %d+B' },
              { find = '; after #%d+' },
              { find = '; before #%d+' },
              { find = '%d fewer lines' },
              { find = '%d more lines' },
            },
          },
          opts = { skip = true },
        },
        {
          view = 'notify',
          filter = {
            event = 'msg_showmode',
            any = {
              { find = 'recording' },
            },
          },
        },
      },
      presets = {
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    }
  end,
  dependencies = {
    'MunifTanjim/nui.nvim',
    {
      'rcarriga/nvim-notify',
      config = function()
        require('notify').setup {
          background_colour = '#000000', -- or "Normal"
        }
      end,
    },
  },
}
