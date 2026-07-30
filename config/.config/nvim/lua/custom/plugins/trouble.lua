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
    keys = {
      s = false, -- disable severity filter to allow flash.nvim
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
      '<leader>cs',
      '<cmd>Trouble symbols toggle focus=true win.size=0.4<cr>',
      desc = 'Symbols (Trouble)',
    },
    {
      '<leader>cl',
      '<cmd>Trouble lsp_no_type_defs toggle focus=true win.position=right win.size=0.3<cr>',
      desc = 'LSP Definitions / references (Trouble)',
    },
  },
}
