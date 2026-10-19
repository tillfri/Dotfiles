return {
  'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup {
      options = {
        theme = 'tokyonight',
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
            path = 4, -- 0 = just filename, 1 = relative path, 2 = absolute path
          },
        },
        lualine_x = {
          {
            function()
              return require('custom.ipynb_kernel').status()
            end,
            color = function()
              return require('custom.ipynb_kernel').color()
            end,
          },
          'encoding',
          'fileformat',
          'filetype',
        },
      },
    }
  end,
}
