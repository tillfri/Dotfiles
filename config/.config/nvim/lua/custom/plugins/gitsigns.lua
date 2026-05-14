-- Adds git related signs to the gutter, as well as utilities for managing changes
return {
  'lewis6991/gitsigns.nvim',
  opts = {
    diff_opts = {
      internal         = true,
      algorithm        = 'histogram',
      indent_heuristic = true,
      linematch        = 60,
    },
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    signs_staged = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end)

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end)

      map('n', '<leader>fd', function()
        local file = vim.fn.expand '%:p'
        local dir = vim.fn.expand '%:p:h'
        local lines = vim.fn.systemlist(
          'git -C ' .. vim.fn.shellescape(dir) .. ' log --follow --pretty=format:%H%x09%s%x09%ar -10 -- ' .. vim.fn.shellescape(file)
        )
        if #lines == 0 then
          vim.notify('No commits found for this file', vim.log.levels.WARN)
          return
        end
        local items = {}
        for _, line in ipairs(lines) do
          local hash, subject, date = line:match('([^\t]+)\t([^\t]+)\t(.*)')
          if hash then
            table.insert(items, {
              text = string.format('%s  %s  (%s)', hash:sub(1, 7), subject, date),
              hash = hash,
            })
          end
        end
        Snacks.picker {
          title = 'Diff with Commit',
          items = items,
          format = function(item)
            return { { item.text, 'Normal' } }
          end,
          preview = function(ctx)
            local output = vim.fn.systemlist(
              'git -C ' .. vim.fn.shellescape(dir) .. ' show ' .. ctx.item.hash .. ' -- ' .. vim.fn.shellescape(file)
            )
            ctx.preview:set_lines(output)
            ctx.preview:highlight { ft = 'diff' }
          end,
          confirm = function(picker, item)
            picker:close()
            if item then
              gitsigns.diffthis(item.hash .. '~1')
            end
          end,
        }
      end)
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
    end,
  },
}
