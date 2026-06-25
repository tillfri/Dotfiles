-- due_calendar.lua
-- Floating calendar picker for inserting dates in 'due:YYYY-MM-DD' format

local M = {}

-- ── Constants ────────────────────────────────────────────────────────────────

local MONTH_NAMES = {
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
}
local MONTH_SHORT = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }
local WEEKDAY_SHORT = { 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' }
local DAY_LETTERS = { 'S', 'M', 'T', 'W', 'T', 'F', 'S' }
local WIN_WIDTH = 44

local ns = vim.api.nvim_create_namespace 'due_calendar'

-- ── State ────────────────────────────────────────────────────────────────────

local state = {
  win = nil,
  buf = nil,
  year = nil,
  month = nil,
  day = nil,
  orig_win = nil,
  orig_buf = nil,
  orig_row = nil,
  orig_col = nil,
  mode = nil, -- 'insert' | 'due'
}

-- True from the moment M.open() is called until state.win is assigned.
-- Blocks any re-entrant call triggered by events fired during setup.
local _in_open = false

-- ── Date helpers ─────────────────────────────────────────────────────────────

local function days_in_month(y, m)
  return tonumber(os.date('%d', os.time { year = y, month = m + 1, day = 0, hour = 12 }))
end

local function first_weekday(y, m)
  return tonumber(os.date('%w', os.time { year = y, month = m, day = 1, hour = 12 }))
end

local function clamp_day(y, m, d)
  return math.min(d, days_in_month(y, m))
end

local function add_months(y, m, delta)
  m = m + delta
  while m > 12 do
    m = m - 12
    y = y + 1
  end
  while m < 1 do
    m = m + 12
    y = y - 1
  end
  return y, m
end

local function add_days(y, m, d, delta)
  local t = os.date('*t', os.time { year = y, month = m, day = d + delta, hour = 12 })
  return t.year, t.month, t.day
end

local function count_weeks(y, m)
  return math.ceil((first_weekday(y, m) + days_in_month(y, m)) / 7)
end

-- ── Grid builder ─────────────────────────────────────────────────────────────

local function build_grid(y, m)
  local fw = first_weekday(y, m)
  local total = days_in_month(y, m)
  local rows, row = {}, {}
  -- Use false (not nil) as the empty-cell sentinel.
  -- table.insert(t, nil) is a no-op in Lua (setting t[k]=nil removes the key),
  -- so #row would never grow and the while-pad loop below would spin forever.
  for _ = 1, fw do
    table.insert(row, false)
  end
  for d = 1, total do
    table.insert(row, d)
    if #row == 7 then
      table.insert(rows, row)
      row = {}
    end
  end
  if #row > 0 then
    while #row < 7 do
      table.insert(row, false)
    end
    table.insert(rows, row)
  end
  return rows
end

-- ── Rendering ────────────────────────────────────────────────────────────────

local _rendering = false

local function render()
  if _rendering then
    return
  end
  local buf = state.buf
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  _rendering = true

  -- Suppress ALL autocmds: nvim_win_set_config fires WinScrolled/WinResized,
  -- nvim_buf_set_lines fires TextChanged/BufModifiedSet. Any plugin listening
  -- on those can re-enter render() and produce a 100% CPU infinite loop.
  local saved_ei = vim.o.eventignore
  vim.o.eventignore = 'all'

  local ok, err = pcall(function()
    local win = state.win
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, { height = 8 + count_weeks(state.year, state.month) })
    end

    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    local lines, hls = {}, {}
    local function L(t)
      table.insert(lines, t or '')
      return #lines - 1
    end
    local function H(li, cs, ce, g)
      table.insert(hls, { li, cs, ce, g })
    end

    local today = os.date '*t'

    L() -- top padding

    local my = MONTH_NAMES[state.month] .. ' ' .. state.year
    local hdr = '  < ' .. my .. ' >'
    local li = L(hdr)
    H(li, 2, 3, 'Comment')
    H(li, 4, 4 + #my, 'Title')
    H(li, 4 + #my + 1, 4 + #my + 2, 'Comment')

    L() -- empty

    local dc = {}
    for _, d in ipairs(DAY_LETTERS) do
      table.insert(dc, string.format('%2s', d))
    end
    local dh = ' ' .. table.concat(dc, ' ')
    li = L(dh)
    H(li, 0, #dh, 'Comment')

    for _, row in ipairs(build_grid(state.year, state.month)) do
      local cells = {}
      for _, d in ipairs(row) do
        table.insert(cells, d and string.format('%2d', d) or '  ')
      end
      li = L(' ' .. table.concat(cells, ' '))
      for c, d in ipairs(row) do
        if d then -- false = empty cell sentinel, skip it
          local cs = 1 + (c - 1) * 3
          local ce = cs + 2
          if d == today.day and state.month == today.month and state.year == today.year then
            H(li, cs, ce, 'DiagnosticHint')
          end
          if d == state.day then
            H(li, math.max(0, cs - 1), ce, 'CursorLine')
          end
        end
      end
    end

    L() -- empty

    local st = os.time { year = state.year, month = state.month, day = state.day, hour = 12 }
    local wd = tonumber(os.date('%w', st))
    local sel = string.format('%s %s %d', WEEKDAY_SHORT[wd + 1], MONTH_SHORT[state.month], state.day)
    li = L('  ' .. sel)
    H(li, 2, 2 + #sel, 'Statement')

    -- · = U+00B7 (middle dot), 2 bytes in UTF-8
    local hints = '  t today \xc2\xb7 T tmw \xc2\xb7 w +1w \xc2\xb7 m +1mo \xc2\xb7 x close'
    li = L(hints)
    H(li, 0, #hints, 'Comment')

    L() -- bottom padding

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    for _, h in ipairs(hls) do
      vim.api.nvim_buf_add_highlight(buf, ns, h[4], h[1], h[2], h[3])
    end
  end)

  vim.o.eventignore = saved_ei
  _rendering = false
  if not ok then
    vim.notify('due_calendar render: ' .. tostring(err), vim.log.levels.ERROR)
  else
  end
end

-- ── Actions ──────────────────────────────────────────────────────────────────

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
  state.buf = nil
end

local function do_confirm()
  local date_str = string.format('%04d-%02d-%02d', state.year, state.month, state.day)
  local ob, ow, or_, oc, mode = state.orig_buf, state.orig_win, state.orig_row, state.orig_col, state.mode
  M.close()
  if ow and vim.api.nvim_win_is_valid(ow) then
    vim.api.nvim_set_current_win(ow)
  end
  if ob and vim.api.nvim_buf_is_valid(ob) then
    vim.api.nvim_buf_set_text(ob, or_, oc, or_, oc, { date_str })
    if mode == 'due' then
      -- Place cursor on the last char of the inserted date, then append after
      -- it. Using `oc + #date_str` would be past the end of the line in normal
      -- mode and get clamped to the last char, causing startinsert to land one
      -- position too early. `normal! a` moves one step right into insert mode.
      vim.api.nvim_win_set_cursor(ow, { or_ + 1, oc + #date_str - 1 })
      vim.cmd 'normal! a'
    else
      vim.api.nvim_win_set_cursor(ow, { or_ + 1, oc + #date_str })
    end
  end
end

local function do_cancel()
  local ow = state.orig_win
  M.close()
  if ow and vim.api.nvim_win_is_valid(ow) then
    vim.api.nvim_set_current_win(ow)
  end
end

-- ── Buffer-local keymaps ─────────────────────────────────────────────────────

local function set_keymaps(buf)
  local o = { noremap = true, silent = true, buffer = buf, nowait = true }

  local function nav_day(d)
    state.year, state.month, state.day = add_days(state.year, state.month, state.day, d)
    render()
  end
  local function nav_month(d)
    local ny, nm = add_months(state.year, state.month, d)
    state.year, state.month, state.day = ny, nm, clamp_day(ny, nm, state.day)
    render()
  end
  local function from_today(days, months)
    local now = os.date '*t'
    if months then
      local ny, nm = add_months(now.year, now.month, months)
      state.year, state.month, state.day = ny, nm, clamp_day(ny, nm, now.day)
    else
      state.year, state.month, state.day = add_days(now.year, now.month, now.day, days or 0)
    end
    render()
  end

  vim.keymap.set('n', 'l', function()
    nav_day(1)
  end, o)
  vim.keymap.set('n', 'h', function()
    nav_day(-1)
  end, o)
  vim.keymap.set('n', '<Right>', function()
    nav_day(1)
  end, o)
  vim.keymap.set('n', '<Left>', function()
    nav_day(-1)
  end, o)
  vim.keymap.set('n', 'j', function()
    nav_day(7)
  end, o)
  vim.keymap.set('n', 'k', function()
    nav_day(-7)
  end, o)
  vim.keymap.set('n', '<Down>', function()
    nav_day(7)
  end, o)
  vim.keymap.set('n', '<Up>', function()
    nav_day(-7)
  end, o)
  vim.keymap.set('n', 'H', function()
    nav_month(-1)
  end, o)
  vim.keymap.set('n', 'L', function()
    nav_month(1)
  end, o)
  vim.keymap.set('n', '[', function()
    nav_month(-1)
  end, o)
  vim.keymap.set('n', ']', function()
    nav_month(1)
  end, o)
  vim.keymap.set('n', 't', function()
    from_today(0)
  end, o)
  vim.keymap.set('n', 'T', function()
    from_today(1)
  end, o)
  vim.keymap.set('n', 'w', function()
    from_today(7)
  end, o)
  vim.keymap.set('n', 'm', function()
    from_today(nil, 1)
  end, o)
  vim.keymap.set('n', '<CR>', do_confirm, o)
  vim.keymap.set('n', 'x', do_cancel, o)
  vim.keymap.set('n', '<Esc>', do_cancel, o)
  vim.keymap.set('n', 'q', do_cancel, o)
end

-- ── Public API ───────────────────────────────────────────────────────────────

function M.open(opts)
  -- _in_open stays true from here until state.win is assigned, blocking any
  -- re-entrant call triggered by synchronous events during setup.
  if _in_open then
    return
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return
  end
  _in_open = true

  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local orig_row = cursor[1] - 1
  local orig_col = (opts and opts.orig_col ~= nil) and opts.orig_col or cursor[2]

  vim.schedule(function()
    -- Suppress ALL events for the entire setup block.
    -- nvim_create_buf  → BufNew / BufAdd
    -- filetype assign  → FileType  (treesitter, cmp, lualine all listen here)
    -- nvim_open_win    → WinNew / WinEnter / BufWinEnter / WinLeave
    -- vim.wo assigns   → OptionSet
    -- stopinsert       → InsertLeave
    -- Any of these can call back into M.open() or render() and spin at 100%.
    local saved_ei = vim.o.eventignore
    vim.o.eventignore = 'all'

    local win, buf
    local ok, err = pcall(function()
      -- Exit insert mode silently (InsertLeave suppressed)
      vim.cmd 'stopinsert'

      local now = os.date '*t'
      state.orig_win = orig_win
      state.orig_buf = orig_buf
      state.orig_row = orig_row
      state.orig_col = orig_col
      state.mode = opts and opts.mode or 'insert'
      state.year = now.year
      state.month = now.month
      state.day = now.day

      buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].buftype = 'nofile'
      vim.bo[buf].bufhidden = 'wipe'
      vim.bo[buf].filetype = 'due_calendar'
      vim.bo[buf].modifiable = false

      win = vim.api.nvim_open_win(buf, true, {
        relative = 'cursor',
        row = 1,
        col = 0,
        width = WIN_WIDTH,
        height = 8 + count_weeks(now.year, now.month),
        style = 'minimal',
        border = 'rounded',
        zindex = 50,
        focusable = true,
      })

      vim.wo[win].wrap = false
      vim.wo[win].cursorline = false
      vim.wo[win].number = false
      vim.wo[win].relativenumber = false
      vim.wo[win].signcolumn = 'no'

      -- Assign to state NOW so subsequent guards block re-entry
      state.buf = buf
      state.win = win
    end)

    vim.o.eventignore = saved_ei -- always restore before anything else
    _in_open = false

    if not ok then
      state.win = nil
      state.buf = nil
      vim.notify('due_calendar: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end

    -- Register cleanup (after events are re-enabled so it fires normally)
    vim.api.nvim_create_autocmd('BufWipeout', {
      buffer = buf,
      once = true,
      callback = function()
        state.win = nil
        state.buf = nil
      end,
    })

    set_keymaps(buf)
    render()
  end)
end

function M.setup(_) end

return M
