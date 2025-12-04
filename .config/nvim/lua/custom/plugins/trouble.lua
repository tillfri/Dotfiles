return {
  'folke/trouble.nvim',
  opts = {
    auto_preview = true,
    auto_close = true,
    focus = true,
    preview = {
      type = 'main',
      -- type = 'split',
      -- relative = 'win',
      -- position = 'bottom',
      -- size = 0.3,
    },
    modes = {
      lsp_references = {
        params = {
          include_declaration = false,
        },
      },
      lsp_base = {
        params = {
          include_current = true,
        },
      },
      -- Custom mode that excludes type definitions
      lsp_no_type_defs = {
        desc = 'LSP definitions, references, and implementations (no type definitions)',
        sections = {
          'lsp_definitions',
          'lsp_references',
          'lsp_implementations',
          'lsp_declarations',
        },
      },
    },
  }, -- for default options, refer to the configuration section for custom setup.
  cmd = 'Trouble',
  keys = {
    {
      '<leader>XX',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Diagnostics (Trouble)',
    },
    {
      '<leader>xx',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Buffer Diagnostics (Trouble)',
    },
    {
      '<leader>cs',
      '<cmd>Trouble symbols toggle focus=true win.size=0.3<cr>',
      desc = 'Symbols (Trouble)',
    },
    {
      '<leader>cl',
      '<cmd>Trouble lsp_no_type_defs toggle focus=true win.position=right win.size=0.3<cr>',
      desc = 'LSP Definitions / references (Trouble)',
    },
    {
      '<leader>xl',
      '<cmd>Trouble loclist toggle<cr>',
      desc = 'Location List (Trouble)',
    },
    {
      '<leader>xq',
      '<cmd>Trouble qflist toggle<cr>',
      desc = 'Quickfix List (Trouble)',
    },
  },
}
