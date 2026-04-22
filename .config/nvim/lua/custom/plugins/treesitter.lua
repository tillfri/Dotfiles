return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'lua',
        'python',
        'javascript',
        'typescript',
        'vimdoc',
        'vim',
        'regex',
        'terraform',
        'sql',
        'dockerfile',
        'toml',
        'json',
        'java',
        'groovy',
        'go',
        'gitignore',
        'graphql',
        'yaml',
        'make',
        'cmake',
        'markdown',
        'markdown_inline',
        'bash',
        'tsx',
        'css',
        'html',
        'hyprlang',
        'cpp',
        'latex',
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'lua',
          'python',
          'javascript',
          'typescript',
          'vimdoc',
          'vim',
          'regex',
          'terraform',
          'sql',
          'dockerfile',
          'toml',
          'json',
          'java',
          'groovy',
          'go',
          'graphql',
          'yaml',
          'make',
          'cmake',
          'markdown',
          'bash',
          'tsx',
          'css',
          'html',
          'cpp',
          'latex',
          'ruby',
        },
        callback = function(ev)
          vim.treesitter.start()
          if ev.match ~= 'ruby' then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        select = { lookahead = true },
        move = { set_jumps = true },
      }

      local sel = require 'nvim-treesitter-textobjects.select'
      local mov = require 'nvim-treesitter-textobjects.move'

      vim.keymap.set({ 'x', 'o' }, 'aa', function()
        sel.select_textobject('@parameter.outer', 'textobjects')
      end, { desc = 'Select outer parameter' })
      vim.keymap.set({ 'x', 'o' }, 'ia', function()
        sel.select_textobject('@parameter.inner', 'textobjects')
      end, { desc = 'Select inner parameter' })
      vim.keymap.set({ 'x', 'o' }, 'af', function()
        sel.select_textobject('@function.outer', 'textobjects')
      end, { desc = 'Select outer function' })
      vim.keymap.set({ 'x', 'o' }, 'if', function()
        sel.select_textobject('@function.inner', 'textobjects')
      end, { desc = 'Select inner function' })
      vim.keymap.set({ 'x', 'o' }, 'ac', function()
        sel.select_textobject('@class.outer', 'textobjects')
      end, { desc = 'Select outer class' })
      vim.keymap.set({ 'x', 'o' }, 'ic', function()
        sel.select_textobject('@class.inner', 'textobjects')
      end, { desc = 'Select inner class' })
      vim.keymap.set({ 'x', 'o' }, 'al', function()
        sel.select_textobject('@loop.outer', 'textobjects')
      end, { desc = 'Select outer loop' })
      vim.keymap.set({ 'x', 'o' }, 'il', function()
        sel.select_textobject('@loop.inner', 'textobjects')
      end, { desc = 'Select inner loop' })
      vim.keymap.set({ 'x', 'o' }, 'ai', function()
        sel.select_textobject('@conditional.outer', 'textobjects')
      end, { desc = 'Select outer conditional' })
      vim.keymap.set({ 'x', 'o' }, 'ii', function()
        sel.select_textobject('@conditional.inner', 'textobjects')
      end, { desc = 'Select inner conditional' })

      vim.keymap.set({ 'n', 'x', 'o' }, ']f', function()
        mov.goto_next_start('@function.outer', 'textobjects')
      end, { desc = 'Next function start' })
      vim.keymap.set({ 'n', 'x', 'o' }, '[f', function()
        mov.goto_previous_start('@function.outer', 'textobjects')
      end, { desc = 'Previous function start' })
      -- vim.keymap.set({ 'n', 'x', 'o' }, ']c', function()
      --   mov.goto_next_start('@class.outer', 'textobjects')
      -- end, { desc = 'Next class start' })
      -- vim.keymap.set({ 'n', 'x', 'o' }, '[c', function()
      --   mov.goto_previous_start('@class.outer', 'textobjects')
      -- end, { desc = 'Previous class start' })
    end,
  },
}
