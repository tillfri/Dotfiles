return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'williamboman/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- JSON/YAML schema catalog from https://www.schemastore.org
    { 'b0o/SchemaStore.nvim', version = false },

    {
      'j-hui/fidget.nvim',
      opts = {
        progress = {
          display = {
            done_icon = '✓', -- Icon shown when all LSP progress tasks are complete
          },
        },
        notification = {
          window = {
            winblend = 0, -- Background color opacity in the notification window
          },
        },
      },
    },
  },
  config = function()
    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local function get_python_path()
      local home = vim.uv.os_homedir()
      local dir = vim.fn.getcwd()

      while dir do
        local python = dir .. '/.venv/bin/python3'
        if vim.fn.executable(python) == 1 then
          return python
        end

        if dir == home or dir == '/' then
          break
        end

        dir = vim.fn.fnamemodify(dir, ':h')
      end

      return vim.NIL
    end

    local servers = {
      clangd = {
        capabilities = {
          offsetEncoding = { 'utf-8' },
        },
      },
      -- gopls = {},
      -- pyright = {},
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`tsserver`) will work just fine
      ts_ls = {}, -- tsserver is deprecated
      ruff = {
        settings = {
          configuration = '~/.config/ruff/ruff.toml',
          configurationPreference = 'filesystemFirst',
        },
      },
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
              jedi = { environment = get_python_path() },
              jedi_completion = { enabled = true, include_params = true },
            },
          },
        },
      },

      texlab = {},
      html = { filetypes = { 'html', 'twig', 'hbs' } },
      cssls = {},
      -- tailwindcss = {},
      dockerls = {},
      sqlls = {},
      terraformls = {},
      jsonls = {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      },
      yamlls = {
        settings = {
          yaml = {
            -- disable the built-in schema store so SchemaStore.nvim is authoritative
            schemaStore = {
              enable = false,
              url = '',
            },
            schemas = require('schemastore').yaml.schemas(),
          },
        },
      },
      omnisharp = {},
      debugpy = {},
      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            runtime = { version = 'LuaJIT' },
            workspace = {
              checkThirdParty = false,
              library = {
                '${3rd}/luv/library',
                unpack(vim.api.nvim_get_runtime_file('', true)),
              },
            },
            diagnostics = {
              globals = { 'vim' },
              disable = { 'missing-fields' },
            },
            format = {
              enable = false,
            },
          },
        },
      },
    }

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})

    vim.list_extend(ensure_installed, {
      'stylua',
      'prettier',
      'shfmt',
    })

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for server, cfg in pairs(servers) do
      cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
      vim.lsp.config(server, cfg)
      vim.lsp.enable(server)
    end
  end,
}
