return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
  opts = {
    ensure_installed = {
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
    }, -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = {
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
          ['al'] = '@loop.outer',
          ['il'] = '@loop.inner',
          ['ii'] = '@conditional.inner',
          ['ai'] = '@conditional.outer',
        },
      },
    },
  },
  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
