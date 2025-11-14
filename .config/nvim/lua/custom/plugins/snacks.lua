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
    {
      '<leader>lg',
      function()
        Snacks.lazygit()
      end,
      desc = 'Toggle Lazygit',
      mode = 'n',
    },
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = '[S]earch [H]elp',
    },
    {
      '<leader>sk',
      function()
        Snacks.picker.keymaps()
      end,
      desc = '[S]earch [K]eymaps',
    },
    {
      '<leader>ff',
      function()
        Snacks.picker.files()
      end,
      desc = '[S]earch [F]iles',
    },
    {
      '<leader>ss',
      function()
        Snacks.picker()
      end,
      desc = '[S]earch [S]elect Picker',
    },
    {
      '<leader>fw',
      function()
        Snacks.picker.grep_word()
      end,
      desc = '[S]earch current [W]ord',
      mode = { 'n', 'x' },
    },
    {
      '<leader>gg',
      function()
        Snacks.picker.grep { hidden = true }
      end,
      desc = '[S]earch by [G]rep',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = '[S]earch [D]iagnostics',
    },
    {
      '<leader>su',
      function()
        Snacks.picker.undo()
      end,
      desc = 'Undo History',
    },
    {
      '<leader>sj',
      function()
        Snacks.picker.jumps()
      end,
      desc = 'Jumps',
    },
    {
      '<leader>sr',
      function()
        Snacks.picker.resume()
      end,
      desc = '[S]earch [R]esume',
    },
    {
      '<leader>s.',
      function()
        Snacks.picker.recent()
      end,
      desc = '[S]earch Recent Files (.)',
    },
    {
      '<leader><leader>',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[ ] Find existing buffers',
    },
    {
      '<leader>:',
      function()
        Snacks.picker.command_history()
      end,
      desc = 'Command History',
    },
    {
      '<leader>n',
      function()
        Snacks.picker.notifications()
      end,
      desc = 'Notification History',
    },
    {
      '<leader>fc',
      function()
        Snacks.picker.files {
          cwd = vim.fn.expand '~/.config',
          hidden = true,
        }
      end,
      desc = 'Find files in .config',
    },
    {
      '<leader>gc',
      function()
        Snacks.picker.grep {
          cwd = vim.fn.expand '~/.config',
          hidden = true,
        }
      end,
      desc = 'Find files using ripgrep in .config',
    },
    {
      '<leader>/',
      function()
        Snacks.picker.lines()
      end,
      desc = '[/] Fuzzily search in current buffer',
    },
    {
      '<leader>fo',
      function()
        Snacks.picker.files {
          cwd = '/mnt/stuff/obsidian_vault',
          hidden = false,
        }
      end,
      desc = 'Find files in Obsidian vault',
    },
    {
      '<leader>go',
      function()
        Snacks.picker.grep {
          cwd = '/mnt/stuff/obsidian_vault',
          hidden = false,
        }
      end,
      desc = 'Grep Obsidian vault',
    },
    {
      '<leader>s/',
      function()
        Snacks.picker.grep_buffers()
      end,
      desc = '[S]earch [/] in Open Files',
    },
    {
      '<leader>sn',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = '[S]earch [N]eovim files',
    },
  },
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = true },
    lazygit = { enabled = true },
    explorer = { enabled = false },
    image = { enabled = true },
    indent = { enabled = true },
    input = { enabled = false },
    picker = {
      enabled = true,
      layout = 'custom',
      layouts = {
        custom = {
          layout = {
            backdrop = false,
            width = 0.5,
            min_width = 80,
            height = 0.8,
            min_height = 30,
            box = 'vertical',
            border = true,
            title = '{title} {live} {flags}',
            title_pos = 'center',
            { win = 'preview', title = '{preview}', height = 0.6, border = 'top' },
            { win = 'list', border = 'top', height = 0.3 },
            { win = 'input', height = 1, border = 'top' },
          },
        },
      },
      win = {
        input = {
          keys = {
            ['<c-u>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['<c-d>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
          },
        },
      },
    },
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
