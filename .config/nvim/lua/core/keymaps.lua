vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local opts = { noremap = true, silent = true }

-- Center screen when jumping half a page up/down
vim.api.nvim_set_keymap('n', '<C-d>', '<C-d>zz', opts)
vim.api.nvim_set_keymap('n', '<C-u>', '<C-u>zz', opts)

-- Jump up half a page when pressing CTRL+a
vim.api.nvim_set_keymap('n', '<C-a>', '<C-u>zz', opts)
vim.api.nvim_set_keymap('v', '<C-a>', '<C-u>zz', opts)

-- Center screen when jumping to next occurence
vim.api.nvim_set_keymap('n', 'n', 'nzzzv', opts)
vim.api.nvim_set_keymap('n', 'N', 'Nzzzv', opts)

-- Search word under cursor using Shift+3
vim.api.nvim_set_keymap('n', '"', '*', opts)
vim.api.nvim_set_keymap('n', '<80><fc>^B§', '*', opts)
vim.api.nvim_set_keymap('v', '/', 'y/<C-R>"', opts)

-- Jump first letter in line using Shift+1
vim.api.nvim_set_keymap('n', '!', '^', opts)

-- CTRL rebinds for easier brackets in insert mode
vim.api.nvim_set_keymap('i', '<C-7>', '{', opts)
vim.api.nvim_set_keymap('i', '<C-8>', '{', opts)
vim.api.nvim_set_keymap('i', '<C-9>', '}', opts)
vim.api.nvim_set_keymap('i', '<C-0>', '}', opts)

-- Remap ( ) to { } in normal mode
vim.api.nvim_set_keymap('n', '(', '{', opts)
vim.api.nvim_set_keymap('n', ')', '}', opts)

vim.keymap.set('n', 'ä', "'", opts)

-- Change working directory to the directory of the currently open file
vim.keymap.set('n', '<leader>cd', function()
  vim.cmd('cd ' .. vim.fn.expand '%:p:h')
  print('Changed directory to ' .. vim.fn.expand '%:p:h')
end, { desc = "Change working directory to the current file's directory" })

-- Space +rp executes current python script with activated .venv if there is one in the same directory as the file
vim.keymap.set('n', '<leader>rp', function()
  -- Get the directory of the currently opened file
  local file_dir = vim.fn.expand '%:p:h'
  local venv_activate = file_dir .. '/.venv/bin/activate'
  local cmd
  if vim.fn.filereadable(venv_activate) == 1 then
    cmd = string.format(':term source %s && python %s', venv_activate, vim.fn.expand '%:p')
    vim.cmd 'startinsert'
  else
    cmd = string.format(':term python %s', vim.fn.expand '%:p')
    vim.cmd 'startinsert'
  end
  vim.cmd(cmd)
end, opts)

-- Space +rc compile and execute current C++ file
vim.keymap.set('n', '<leader>rc', function()
  local filepath = vim.fn.expand '%:p' -- Full path of the current file
  local output = vim.fn.expand '%:r' -- Filename without extension

  -- Compile the file
  local compile_cmd = string.format('g++ -std=c++17 -Wall -o %s %s', output, filepath)
  local compile_result = vim.fn.system(compile_cmd) -- Use vim.fn.system for better control

  -- Check if compilation was successful
  if vim.v.shell_error == 0 then
    -- Run the file in a terminal and enter insert mode
    vim.cmd(string.format('term ./%s', output))
    vim.cmd 'startinsert'
  else
    print 'Compilation failed!'
    print(compile_result) -- Print the compilation errors
  end
end, { desc = 'Compile and run current C++ file' })

-- Space +d Delete without yanking deleted content
vim.keymap.set('n', '<leader>d', '"_d', { noremap = true, silent = true, desc = 'Delete to void register' })
vim.keymap.set('v', '<leader>d', '"_d', { noremap = true, silent = true, desc = 'Delete to void register' })

-- delete/replace character shouldnt be yanked
vim.keymap.set('n', 'x', '"_x', opts)

-- Save file using CTRL+s
vim.keymap.set('n', '<C-s>', '<cmd> w <CR>', opts)

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
--  Till
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
--  Till Interesting
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Resize with arrows
vim.keymap.set('n', '<Up>', ':resize -2<CR>', opts)
vim.keymap.set('n', '<Down>', ':resize +2<CR>', opts)
vim.keymap.set('n', '<Left>', ':vertical resize -2<CR>', opts)
vim.keymap.set('n', '<Right>', ':vertical resize +2<CR>', opts)

-- Buffers
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts)
vim.keymap.set('n', '<leader>x', ':bdelete!<CR>', opts) -- close buffer
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer

-- Window management
vim.keymap.set('n', '<leader>v', '<C-w>v', opts) -- split window vertically
vim.keymap.set('n', '<leader>h', '<C-w>s', opts) -- split window horizontally
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', ':close<CR>', opts) -- close current split window

-- Keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP', opts)
