return {
  'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup {
      options = {
        theme = 'dracula',
        ignore_focus = {
          'dapui_scopes',
          'dapui_breakpoints',
          'dapui_stacks',
          'dapui_watches',
          'dapui_console',
          'dap-repl',
          'trouble',
        },
      },
      sections = {
        lualine_c = {
          {
            'filename',
            path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
          },
        },
      },
    }
  end,
}
