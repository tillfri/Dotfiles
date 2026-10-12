return {
  'ajbucci/ipynb.nvim',
  -- Pinned to the security-audited commit; review the diff before bumping.
  commit = '9c06504b2597404eceda7da18fd68c0d55edbb4e',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'neovim/nvim-lspconfig',
    'nvim-tree/nvim-web-devicons',
    'folke/snacks.nvim',
  },
  opts = {
    kernel = {
      python_path = vim.fn.expand '~/.venvs/monorepo-pytest/bin/python',
    },
  },
  init = function()
    vim.keymap.set({ 'n', 'x' }, '<leader>kl', function()
      require('custom.ipynb_lens').open()
    end, { desc = 'Notebook: view expression in csvlens' })
  end,
}
