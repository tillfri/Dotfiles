-- due-calendar.lua
-- Lazy.nvim spec for the due_calendar local plugin.
-- The implementation lives at lua/due_calendar.lua (already on the runtimepath).

return {
  -- Local plugin: no git URL needed, the nvim config dir is already loaded.
  dir  = vim.fn.stdpath('config'),
  name = 'due-calendar',
  lazy = false,
  config = function()
    local cal = require('due_calendar')
    cal.setup()

    -- <leader>ca  →  open calendar in normal mode; inserts date at cursor
    vim.keymap.set('n', '<leader>ca', function()
      cal.open({ mode = 'insert' })
    end, { noremap = true, silent = true, desc = '[C]alendar: pick d[a]te' })

    -- Auto-trigger: open calendar when "due:" is typed in a markdown file.
    -- InsertCharPre fires exactly once per keystroke, before the char is inserted.
    -- We check for ':' after "due", then pass orig_col = col+1 so the insertion
    -- point lands after the ':' that is about to be committed.
    vim.api.nvim_create_autocmd('InsertCharPre', {
      pattern  = '*.md',
      callback = function()
        if vim.v.char ~= ':' then return end

        local col    = vim.api.nvim_win_get_cursor(0)[2]
        local line   = vim.api.nvim_get_current_line()
        local before = line:sub(1, col) -- text before the cursor (colon not yet in)
        local after  = line:sub(col + 1)

        -- Only trigger when we're completing "due:" at end of meaningful content
        if before:match('due$') and after:match('^%s*$') then
          cal.open({ mode = 'due', orig_col = col + 1 })
        end
      end,
    })
  end,
}
