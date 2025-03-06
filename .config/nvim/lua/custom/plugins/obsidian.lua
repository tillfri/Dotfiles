return {
  'epwalsh/obsidian.nvim',
  version = '*',
  lazy = true,
  ft = 'markdown',
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    workspaces = {
      {
        name = 'obsidian_vault',
        path = '/mnt/stuff/obsidian_vault',
      },
    },
    disable_frontmatter = true,
    notes_subdir = 'inbox',
    new_notes_location = 'notes_subdir',
    templates = {
      subdir = 'templates',
      date_format = '%d-%m-%Y',
      time_format = '%H:%M:%S',
    },

    completion = {
      -- Set to false to disable completion.
      nvim_cmp = true,
      -- Trigger completion at 2 chars.
      min_chars = 2,
    },
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ['gf'] = {
        action = function()
          return require('obsidian').util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ['<leader>ch'] = {
        action = function()
          return require('obsidian').util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
    },
  },
  -- convert note to template and remove leading white space
  vim.keymap.set('n', '<leader>on', ':ObsidianTemplate template<cr> :lua vim.cmd([[1,/^\\S/s/^\\n\\{1,}//]])<cr>'),
}
