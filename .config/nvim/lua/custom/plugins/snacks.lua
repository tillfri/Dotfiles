return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  keys = {
    {
      '<leader>tz',
      function()
        Snacks.zen()
      end,
      desc = 'Toggle Zen Mode',
      mode = 'n',
    },
  },
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    explorer = { enabled = false },
    indent = { enabled = true },
    input = { enabled = false },
    picker = { enabled = false },
    notifier = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    zen = { enabled = true, toggles = { indent = false, diagnostics = false } },
    scroll = { enabled = false },
    styles = {
      zen = {
        enter = true,
        fixbuf = false,
        minimal = false,
        width = 0,
        height = 0,
        backdrop = { transparent = true, blend = 40 },
        keys = { q = false },
        zindex = 40,
        wo = {
          winhighlight = 'NormalFloat:Normal',
        },
        w = {
          snacks_main = true,
        },
      },
    },
  },
}
