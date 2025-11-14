return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
      'MunifTanjim/nui.nvim',
    },
    cmd = 'Neotree',
    keys = {
      -- { '<C-n>', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
      { '<C-n>', ':Neotree toggle position=left<CR>', desc = 'NeoTree reveal', noremap = true, silent = true },
    },
    opts = {
      filesystem = {
        window = {
          mappings = {
            ['\\'] = 'close_window',
          },
        },
      },
    },
  },
  {
    -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = true },
  },
  {
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  },
  { -- Collection of various small independent plugins/modules
    'nvim-mini/mini.nvim',
    version = '*',
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
      --  - ci'  - [C]hange [I]nside [']quote
      require('mini.ai').setup { n_lines = 500 }
      -- require('mini.jump').setup {
      --   delay = {
      --     highlight = 100000,
      --   },
      -- }
      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require('mini.surround').setup()
      require('mini.pairs').setup {
        -- In which modes mappings from this `config` should be created
        modes = { insert = true, command = false, terminal = false },
        -- Global mappings. Each right hand side should be a pair information, a
        -- table with at least these fields (see more in |MiniPairs.map|):
        -- - <action> - one of 'open', 'close', 'closeopen'.
        -- - <pair> - two character string for pair to be used.
        -- By default pair is not inserted after `\`, quotes are not recognized by
        -- `<CR>`, `'` does not insert pair after a letter.
        -- Only parts of tables can be tweaked (others will use these defaults).
        mappings = {
          ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
          ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
          ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },
          ['<C-8>'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

          [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
          [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
          ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
          ['<C-9>'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

          ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
          ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
          ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
        },
      }
    end,
  },
  {
    -- high-performance color highlighter
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
}

-- return { -- Fuzzy Finder (files, lsp, etc)
--   'nvim-telescope/telescope.nvim',
--   event = 'VimEnter',
--   branch = 'master',
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     { -- If encountering errors, see telescope-fzf-native README for installation instructions
--       'nvim-telescope/telescope-fzf-native.nvim',
--
--       -- `build` is used to run some command when the plugin is installed/updated.
--       -- This is only run then, not every time Neovim starts up.
--       build = 'make',
--
--       -- `cond` is a condition used to determine whether this plugin should be
--       -- installed and loaded.
--       cond = function()
--         return vim.fn.executable 'make' == 1
--       end,
--     },
--     { 'nvim-telescope/telescope-ui-select.nvim' },
--
--     -- Useful for getting pretty icons, but requires a Nerd Font.
--     { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
--   },
--   config = function()
--     -- Telescope is a fuzzy finder that comes with a lot of different things that
--     -- it can fuzzy find! It's more than just a "file finder", it can search
--     -- many different aspects of Neovim, your workspace, LSP, and more!
--     --
--     -- The easiest way to use Telescope, is to start by doing something like:
--     --  :Telescope help_tags
--     --
--     -- After running this command, a window will open up and you're able to
--     -- type in the prompt window. You'll see a list of `help_tags` options and
--     -- a corresponding preview of the help.
--     --
--     -- Two important keymaps to use while in Telescope are:
--     --  - Insert mode: <c-/>
--     --  - Normal mode: ?
--     --
--     -- This opens a window that shows you all of the keymaps for the current
--     -- Telescope picker. This is really useful to discover what Telescope can
--     -- do as well as how to actually do it!
--
--     -- [[ Configure Telescope ]]
--     -- See `:help telescope` and `:help telescope.setup()`
--     require('telescope').setup {
--       -- You can put your default mappings / updates / etc. in here
--       --  All the info you're looking for is in `:help telescope.setup()`
--       --
--       defaults = {
--         mappings = {
--           i = {
--             ['<C-k>'] = require('telescope.actions').move_selection_previous, -- move to prev result
--             ['<C-j>'] = require('telescope.actions').move_selection_next, -- move to next result
--             ['<Up>'] = require('telescope.actions').move_selection_previous, -- move to prev result
--             ['<Down>'] = require('telescope.actions').move_selection_next, -- move to next result
--             ['<C-l>'] = require('telescope.actions').select_default, -- open file
--           },
--         },
--         layout_strategy = 'vertical',
--       },
--       pickers = {
--         find_files = {
--           file_ignore_patterns = { 'node_modules', '.git', '.venv' },
--           hidden = true,
--         },
--       },
--       live_grep = {
--         file_ignore_patterns = { 'node_modules', '.git', '.venv' },
--         additional_args = function(_)
--           return { '--hidden' }
--         end,
--       },
--       extensions = {
--         ['ui-select'] = {
--           require('telescope.themes').get_dropdown(),
--         },
--       },
--     }
--
--     -- Enable Telescope extensions if they are installed
--     pcall(require('telescope').load_extension, 'fzf')
--     pcall(require('telescope').load_extension, 'ui-select')
--
--     -- See `:help telescope.builtin`
--     local builtin = require 'telescope.builtin'
--     vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
--     vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
--     vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[S]earch [F]iles' })
--     vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
--     vim.keymap.set('n', '<leader>fw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
--     vim.keymap.set('n', '<leader>gg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
--     vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
--     vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
--     vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
--     vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
--     vim.keymap.set('n', '<leader>fc', function()
--       require('telescope.builtin').find_files {
--         cwd = '~/.config', -- Start in the .config directory
--         hidden = true, -- Show hidden files
--       }
--     end, { desc = 'Find files in .config' })
--     vim.keymap.set('n', '<leader>gc', function()
--       require('telescope.builtin').live_grep {
--         cwd = '~/.config', -- Start in the .config directory
--         hidden = true, -- Show hidden files
--       }
--     end, { desc = 'Find files using ripgrep in .config' })
--     vim.api.nvim_set_keymap('n', '<leader>ft', ':TodoTelescope<CR>', { noremap = true })
--     -- Slightly advanced example of overriding default behavior and theme
--     vim.keymap.set('n', '<leader>/', function()
--       -- You can pass additional configuration to Telescope to change the theme, layout, etc.
--       builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
--         winblend = 10,
--         previewer = false,
--       })
--     end, { desc = '[/] Fuzzily search in current buffer' })
--
--     -- search for files in full vault
--     vim.keymap.set('n', '<leader>fo', function()
--       require('telescope.builtin').find_files {
--         cwd = '/mnt/stuff/obsidian_vault', -- Start in the .config directory
--         hidden = false, -- Show hidden files
--       }
--     end, { desc = 'Find files in .config' })
--     vim.keymap.set('n', '<leader>go', function()
--       require('telescope.builtin').live_grep {
--         cwd = '/mnt/stuff/obsidian_vault', -- Start in the .config directory
--         hidden = false, -- Show hidden files
--       }
--     end, { desc = 'Find files using ripgrep in .config' })
--
--     -- It's also possible to pass additional configuration options.
--     --  See `:help telescope.builtin.live_grep()` for information about particular keys
--     vim.keymap.set('n', '<leader>s/', function()
--       builtin.live_grep {
--         grep_open_files = true,
--         prompt_title = 'Live Grep in Open Files',
--       }
--     end, { desc = '[S]earch [/] in Open Files' })
--
--     -- Shortcut for searching your Neovim configuration files
--     vim.keymap.set('n', '<leader>sn', function()
--       builtin.find_files { cwd = vim.fn.stdpath 'config' }
--     end, { desc = '[S]earch [N]eovim files' })
--   end,
-- }

-- return {
--   {
--     'mfussenegger/nvim-dap',
--     dependencies = {
--       'nvim-neotest/nvim-nio',
--       'rcarriga/nvim-dap-ui',
--       'mfussenegger/nvim-dap-python',
--       'theHamsta/nvim-dap-virtual-text',
--     },
--     config = function()
--       local dap = require 'dap'
--       local dapui = require 'dapui'
--       local dap_python = require 'dap-python'
--
--       require('dapui').setup {}
--       require('nvim-dap-virtual-text').setup {
--         commented = true, -- Show virtual text alongside comment
--       }
--
--       dap_python.setup '~/.local/share/nvim/mason/packages/debugpy/venv/bin/python'
--
--       vim.fn.sign_define('DapBreakpoint', {
--         text = '',
--         texthl = 'DiagnosticSignError',
--         linehl = '',
--         numhl = '',
--       })
--
--       vim.fn.sign_define('DapBreakpointRejected', {
--         text = '', -- or "❌"
--         texthl = 'DiagnosticSignError',
--         linehl = '',
--         numhl = '',
--       })
--
--       vim.fn.sign_define('DapStopped', {
--         text = '', -- or "→"
--         texthl = 'DiagnosticSignWarn',
--         linehl = 'Visual',
--         numhl = 'DiagnosticSignWarn',
--       })
--
--       -- Automatically open/close DAP UI
--       dap.listeners.after.event_initialized['dapui_config'] = function()
--         dapui.open()
--       end
--
--       vim.keymap.set('n', '<leader>db', function()
--         dap.toggle_breakpoint()
--       end, { noremap = true, silent = true, desc = 'Debugger: Toggle breakpoint' })
--
--       vim.keymap.set('n', '<leader>dc', function()
--         dap.continue()
--       end, { noremap = true, silent = true, desc = 'Debugger: Start/Continue debugging' })
--
--       vim.keymap.set('n', '<leader>do', function()
--         dap.step_over()
--       end, { noremap = true, silent = true, desc = 'Debugger: Step over' })
--
--       vim.keymap.set('n', '<leader>di', function()
--         dap.step_into()
--       end, { noremap = true, silent = true, desc = 'Debugger: Step into' })
--
--       vim.keymap.set('n', '<leader>dO', function()
--         dap.step_out()
--       end, { noremap = true, silent = true, desc = 'Debugger: Step out' })
--
--       vim.keymap.set('n', '<leader>dq', function()
--         require('dap').terminate()
--       end, { noremap = true, silent = true, desc = 'Debugger: Terminate debugging' })
--
--       vim.keymap.set('n', '<leader>du', function()
--         dapui.toggle()
--       end, { noremap = true, silent = true, desc = 'Debugger: Toggle DAP UI' })
--     end,
--   },
-- }
