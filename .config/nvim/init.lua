vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.g.mapleader = " "
-- require("config.lazy")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Adding settings from .ideavimrc
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.clipboard = "unnamedplus"
-- Key mappings
vim.api.nvim_set_keymap("n", "<C-d>", "<C-d>zz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-u>", "<C-u>zz", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "n", "nzzzv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "N", "Nzzzv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-j>", "<C-u>zz", { noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "§", "*", { noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "!", "^", { noremap = true, silent = true})
vim.api.nvim_set_keymap("i", "<C-7>", "{", { noremap = true, silent = true})
vim.api.nvim_set_keymap("i", "<C-8>", "[", { noremap = true, silent = true})
vim.api.nvim_set_keymap("i", "<C-9>", "]", { noremap = true, silent = true})
vim.api.nvim_set_keymap("i", "<C-0>", "}", { noremap = true, silent = true})

-- Remap ( and ) to function as { and } in normal mode
vim.keymap.set('n', '(', '{', { noremap = true, silent = true })
vim.keymap.set('n', ')', '}', { noremap = true, silent = true })
