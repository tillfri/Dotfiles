local M = {}

-- highlight yank
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  pattern = '*',
  desc = 'highlight selection on yank',
  callback = function()
    vim.highlight.on_yank { timeout = 150, visual = true }
  end,
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd('VimResized', {
  command = 'wincmd =',
})

-- no auto continue comments on new line
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('no_auto_comment', {}),
  callback = function()
    vim.opt_local.formatoptions:remove { 'c', 'r', 'o' }
  end,
})

-- open help in vertical split
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'help',
  command = 'wincmd L',
})

local macro_group = vim.api.nvim_create_augroup('MacroRecording', { clear = true })
-- Notify when macro recording stops.
vim.api.nvim_create_autocmd('RecordingLeave', {
  group = macro_group,
  callback = function()
    print 'Macro recording stopped'
  end,
})

local lsp_attach_group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true })
-- Apply buffer-local LSP keymaps whenever a language server attaches.
vim.api.nvim_create_autocmd('LspAttach', {
  group = lsp_attach_group,
  callback = function(event)
    local function map(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    local ok, snacks = pcall(require, 'snacks')
    if ok and snacks.picker then
      -- map('gd', function() snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')
      -- map('grr', function() snacks.picker.lsp_references() end, '[G]oto [R]eferences')
      -- map('gri', function() snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')
      -- TODO: this doesnt work yet
      map('<leader>ds', function()
        snacks.picker.lsp_symbols()
      end, '[D]ocument [S]ymbols')
      map('<leader>ws', function()
        snacks.picker.lsp_workspace_symbols()
      end, '[W]orkspace [S]ymbols')
      map('<leader>D', function()
        snacks.picker.lsp_type_definitions()
      end, 'Type [D]efinition')
    end

    -- map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    -- map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
    -- map('K', vim.lsp.buf.hover, 'Hover Documentation')
    -- map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

local format_group = vim.api.nvim_create_augroup('LspFormatting', {})

function M.setup_format_on_save(bufnr)
  vim.api.nvim_clear_autocmds { group = format_group, buffer = bufnr }
  -- Format supported buffers before writing to disk.
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = format_group,
    buffer = bufnr,
    callback = function()
      local ft = vim.bo[bufnr].filetype
      local excluded = { c = true, cpp = true }
      if excluded[ft] then
        return
      end
      vim.lsp.buf.format { async = false }
    end,
  })
end

return M
