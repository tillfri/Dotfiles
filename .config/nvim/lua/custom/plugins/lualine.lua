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
    }
  end,
}
