return {
  'iamcco/markdown-preview.nvim',
  cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
  build = 'cd app && npm install',
  ft = { 'markdown' },
  keys = {
    {
      '<leader>tm',
      ft = 'markdown',
      '<cmd>MarkdownPreviewToggle<cr>',
      desc = 'Markdown Preview',
    },
  },
  init = function()
    -- The default filename is 「${name}」and I just hate those symbols
    vim.g.mkdp_page_title = '${name}'
  end,
}
