return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      -- transparent_background = true,
      flavour = 'mocha',
    }
    vim.cmd.colorscheme 'catppuccin'
    vim.cmd [[
        highlight CursorLineNr guifg=#e79c75 gui=bold
      ]]
  end,
}
