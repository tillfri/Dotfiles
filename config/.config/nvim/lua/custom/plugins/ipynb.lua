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
    keymaps = {
      kernel_interrupt = '<leader>kI', -- frees <leader>ki for the full-value view below
    },
  },
  config = function(_, opts)
    require('ipynb').setup(opts)
    require('custom.ipynb_visuals').setup()
    require('custom.ipynb_kernel').setup()

    -- Autostart the kernel on open (the plugin's kernel.auto_connect option is
    -- declared but never read). Same call as <leader>ks.
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'ipynb',
      group = vim.api.nvim_create_augroup('IpynbAutostart', { clear = true }),
      callback = function(args)
        vim.schedule(function()
          local state = require('ipynb.state').get_by_facade(args.buf)
          if state and not (state.kernel and state.kernel.job_id) then
            require('ipynb.kernel').connect(state, {})
          end
        end)
      end,
    })
  end,
  init = function()
    vim.keymap.set({ 'n', 'x' }, '<leader>kl', function()
      require('custom.ipynb_lens').open()
    end, { desc = 'Notebook: view expression in csvlens' })
    vim.keymap.set({ 'n', 'x' }, '<leader>ki', function()
      require('custom.ipynb_lens').full()
    end, { desc = 'Notebook: show full value of expression' })
  end,
}
