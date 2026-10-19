-- Make ipynb.nvim cells easier to scan: brighter borders, a full-width
-- background tint per cell (code and markdown cells get different tints), and
-- an execution indicator on the left of the top border that also shows how
-- the cell's last run in this kernel session ended and how long it took:
--
--   ╭─[󰔟]─ python ───────────╮   queued (sent, kernel hasn't started it yet)
--   ╭─[󰦖 12 · 1m05s]─ python ─╮   running, with elapsed time (ticks every second)
--   ╭─[󰄬 12 · 2.4s]─ python ──╮   finished OK, with run time
--   ╭─[󰅖 12 · 2.4s]─ python ──╮   finished with an error
--   ╭─[󰏫 12 · 2.4s]─ python ──╮   finished, but the code was edited since
--   ╭─[12]─ python ───────────╮   count from the file / an earlier kernel (dimmed)
--
-- Runs from this kernel session are also shown on the left of the bottom
-- border (╰─[󰦖 12 · 1m05s]──────╯), so long cells show their state at both ends.
--
-- The tint is drawn in our own namespace by wrapping ipynb.visuals.render_all,
-- which the plugin calls after every structural change and every kernel state
-- update. The indicator rewrites the plugin's top- and bottom-border extmarks by
-- wrapping ipynb.visuals.render_cell. This relies on internals (visuals.render_all,
-- visuals.render_cell and its 'notebook_visuals' namespace and border segment
-- layout, cells.get_cell_range, kernel.connect/restart/execute, cell.execution_state),
-- so re-check this file when bumping the plugin's pinned commit.

local M = {}

local ns = vim.api.nvim_create_namespace 'ipynb_cell_tint'
-- The plugin's namespace; nvim_create_namespace returns the existing id.
local visual_ns = vim.api.nvim_create_namespace 'notebook_visuals'

---Run record per notebook state, then per cell id: { status, source, start, finish }.
---status: 'queued' | 'running' | 'ok' | 'error'; source: the code that was sent;
---start/finish: hrtime when the kernel started/finished it (start is nil when
---the cell finished before we saw it running).
local runs = setmetatable({}, { __mode = 'k' })

---Repeating timer that redraws running cells so their elapsed time ticks.
local ticker

local icons = { queued = '󰔟', running = '󰦖', ok = '󰄬', error = '󰅖', modified = '󰏫' }
local icon_hl = {
  queued = 'IpynbQueued',
  running = 'IpynbExecuting',
  ok = 'IpynbRunOk',
  error = 'IpynbRunError',
  modified = 'IpynbRunModified',
}

---Mix two '#rrggbb' colors; alpha = weight of fg.
local function blend(fg, alpha, bg)
  local function rgb(hex)
    return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
  end
  local fr, fg_, fb = rgb(fg)
  local br, bg_, bb = rgb(bg)
  local function mix(a, b)
    return math.floor(a * alpha + b * (1 - alpha) + 0.5)
  end
  return string.format('#%02x%02x%02x', mix(fr, br), mix(fg_, bg_), mix(fb, bb))
end

---'#rrggbb' of a highlight group's attribute, or the fallback.
local function color(group, attr, fallback)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  return hl[attr] and string.format('#%06x', hl[attr]) or fallback
end

local function set_highlights()
  local bg = color('Normal', 'bg', '#222436')
  local fg = color('Normal', 'fg', '#c8d3f5')
  local blue = color('Function', 'fg', '#82aaff')
  local orange = color('Constant', 'fg', '#ff966c')

  vim.api.nvim_set_hl(0, 'IpynbBorder', { fg = blend(blue, 0.55, bg) })
  vim.api.nvim_set_hl(0, 'IpynbBorderHover', { fg = orange, bold = true })
  -- Output: readable, but dimmer than cell content (which uses full Normal fg).
  vim.api.nvim_set_hl(0, 'IpynbOutput', { fg = blend(fg, 0.75, bg), italic = true })
  -- Code cells a bit lighter (bluish), markdown cells a bit darker than Normal;
  -- both stay distinct from CursorLine.
  vim.api.nvim_set_hl(0, 'IpynbCodeCell', { bg = blend(blue, 0.07, bg) })
  vim.api.nvim_set_hl(0, 'IpynbMarkdownCell', { bg = blend('#000000', 0.18, bg) })
  vim.api.nvim_set_hl(0, 'IpynbRunOk', { link = 'DiagnosticOk' })
  vim.api.nvim_set_hl(0, 'IpynbRunError', { link = 'DiagnosticError' })
  vim.api.nvim_set_hl(0, 'IpynbRunModified', { link = 'DiagnosticInfo' })
end

---Tint every line of every cell, top border through bottom border.
local function render_tint(state)
  local buf = state.facade_buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Only redraw when the text or cell types changed; render_all also fires on
  -- every (throttled) cursor move.
  local types = {}
  for i, cell in ipairs(state.cells) do
    types[i] = cell.type
  end
  local key = vim.api.nvim_buf_get_changedtick(buf) .. ':' .. table.concat(types, ',')
  if vim.b[buf].ipynb_tint_key == key then
    return
  end
  vim.b[buf].ipynb_tint_key = key

  local cells = require 'ipynb.cells'
  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, cell in ipairs(state.cells) do
    local first, last = cells.get_cell_range(state, i)
    if first and last and last < line_count then
      local hl = cell.type == 'markdown' and 'IpynbMarkdownCell' or 'IpynbCodeCell'
      for line = first, last do
        vim.api.nvim_buf_set_extmark(buf, ns, line, 0, { line_hl_group = hl, priority = 10 })
      end
    end
  end
end

local function count_of(cell)
  local count = cell.execution_count
  return count ~= vim.NIL and count or nil
end

local function has_error(cell)
  for _, out in ipairs(cell.outputs or {}) do
    if out.output_type == 'error' then
      return true
    end
  end
  return false
end

---Redraw the running cells of every notebook; stop once nothing is running.
local function tick()
  local running = false
  for state, records in pairs(runs) do
    local indices = {}
    for i, cell in ipairs(state.cells or {}) do
      local r = cell.id and records[cell.id]
      if r and r.status == 'running' then
        table.insert(indices, i)
      end
    end
    if #indices > 0 and vim.api.nvim_buf_is_valid(state.facade_buf) then
      running = true
      require('ipynb.visuals').render_all(state, indices)
    end
  end
  if not running then
    ticker:stop()
  end
end

local function start_ticker()
  ticker = ticker or vim.uv.new_timer()
  if not ticker:is_active() then
    ticker:start(1000, 1000, vim.schedule_wrap(tick))
  end
end

---Advance each code cell's run record from the plugin's execution_state.
---The plugin marks a cell 'busy' as soon as it is sent, so it only counts as
---running once the kernel has assigned it an execution count (cleared on send
---by the kernel.execute wrapper below).
local function track_runs(state)
  runs[state] = runs[state] or {}
  local records = runs[state]
  for _, cell in ipairs(state.cells) do
    if cell.type == 'code' and cell.id then
      local r = records[cell.id]
      local active = r and (r.status == 'queued' or r.status == 'running')
      if cell.execution_state == 'busy' then
        if not active then
          r = { status = 'queued', source = cell.source }
          records[cell.id] = r
        end
        if r.status == 'queued' and count_of(cell) then
          r.status = 'running'
          r.start = vim.uv.hrtime()
          start_ticker()
        end
      elseif active then
        if r.status == 'running' or count_of(cell) then
          r.status = has_error(cell) and 'error' or 'ok'
          r.finish = vim.uv.hrtime()
        else
          -- Went idle without ever starting: aborted by an interrupt.
          records[cell.id] = nil
        end
      end
    end
  end
end

---'2.4s', '42s', '3m05s', '1h02m'. Whole seconds while live, as it ticks per second.
local function format_duration(ns, live)
  local s = ns / 1e9
  if s < 10 and not live then
    return string.format('%.1fs', s)
  end
  s = math.floor(s)
  if s < 60 then
    return s .. 's'
  elseif s < 3600 then
    return string.format('%dm%02ds', math.floor(s / 60), s % 60)
  end
  return string.format('%dh%02dm', math.floor(s / 3600), math.floor(s % 3600 / 60))
end

---Indicator chunks for a code cell and its run status (nil when not run in
---this kernel session), or nil when there is nothing to show.
local function indicator(state, cell)
  local r = runs[state] and runs[state][cell.id]
  local status = r and r.status
  if (status == 'ok' or status == 'error') and cell.source ~= r.source then
    status = 'modified'
  end
  local count = status ~= 'queued' and count_of(cell) or nil
  if not status and not count then
    return nil
  end

  -- Counts not produced in this kernel session are dimmed.
  local text_hl = status and 'IpynbExecCount' or 'IpynbHint'
  local chunks = { { '[', text_hl } }
  if status then
    table.insert(chunks, { icons[status], icon_hl[status] })
  end
  if count then
    table.insert(chunks, { (status and ' ' or '') .. count, text_hl })
  end
  local start = r and r.start
  if start and status ~= 'queued' then
    local live = status == 'running'
    local elapsed = (live and vim.uv.hrtime() or r.finish) - start
    table.insert(chunks, { ' · ' .. format_duration(elapsed, live), text_hl })
  end
  table.insert(chunks, { ']', text_hl })
  return chunks, status
end

---Splice the indicator in after the left corner of a border line, taking its
---width out of the border's longest run of '─' so the line keeps its width.
---With count and state hidden, the plugin's segments are:
---  top:    {'╭' .. label}, [hint...], {fill}, {'╮'}
---  bottom: {'╰' .. fill .. '╯'}, or with hints {'╰───'}, hints..., {fill}, [hint], {'────╯'}
local function splice(buf, row, corner, chunks)
  local marks = vim.api.nvim_buf_get_extmarks(buf, visual_ns, { row, 0 }, { row, -1 }, { details = true })
  for _, mark in ipairs(marks) do
    local details = mark[4]
    local segs = details.virt_text
    if details.virt_text_pos == 'overlay' and segs then
      local first, border_hl = segs[1][1], segs[1][2]
      if first:sub(1, #corner) ~= corner then
        return -- layout changed upstream; leave the plugin's border alone
      end

      local added = 2
      local new = { { corner .. '─', border_hl } }
      for _, chunk in ipairs(chunks) do
        table.insert(new, chunk)
        added = added + vim.fn.strdisplaywidth(chunk[1])
      end
      local rest = { { '─' .. first:sub(#corner + 1), border_hl } }
      for i = 2, #segs do
        table.insert(rest, segs[i])
      end

      local fill, most = nil, 0
      for _, seg in ipairs(rest) do
        if seg[2] == border_hl then
          local _, n = seg[1]:gsub('─', '')
          if n > most then
            fill, most = seg, n
          end
        end
      end
      if most < added then
        return -- window too narrow; leave the plugin's border alone
      end
      fill[1] = (fill[1]:gsub('─', '', added))
      vim.list_extend(new, rest)

      vim.api.nvim_buf_set_extmark(buf, visual_ns, row, 0, {
        id = mark[1],
        virt_text = new,
        virt_text_pos = 'overlay',
        priority = details.priority,
      })
      return
    end
  end
end

---Draw the indicator on the top border, and on the bottom border too for runs
---from this kernel session.
local function draw_indicator(state, cell_idx, buf)
  local chunks, status = indicator(state, state.cells[cell_idx])
  local top, bottom = require('ipynb.cells').get_cell_range(state, cell_idx)
  if not chunks or not top then
    return
  end
  splice(buf, top, '╭', chunks)
  if status and bottom then
    splice(buf, bottom, '╰', chunks)
  end
end

function M.setup()
  set_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('IpynbVisuals', { clear = true }),
    callback = set_highlights,
  })

  local visuals = require 'ipynb.visuals'
  local render_all = visuals.render_all
  visuals.render_all = function(state, ...)
    track_runs(state)
    render_all(state, ...)
    render_tint(state)
  end

  local render_cell = visuals.render_cell
  visuals.render_cell = function(state, cell_idx, is_active, target_buf)
    local cell = state.cells[cell_idx]
    if not (cell and cell.type == 'code') then
      return render_cell(state, cell_idx, is_active, target_buf)
    end
    -- Hide count/state so the plugin draws no right-hand indicator.
    local count, exec_state = cell.execution_count, cell.execution_state
    cell.execution_count, cell.execution_state = nil, nil
    local ok, err = pcall(render_cell, state, cell_idx, is_active, target_buf)
    cell.execution_count, cell.execution_state = count, exec_state
    if not ok then
      error(err, 0)
    end
    draw_indicator(state, cell_idx, target_buf or state.facade_buf)
  end

  -- Edits in a cell's float only re-render on line-count changes or when the
  -- float closes; re-render the cell when leaving insert mode or after a
  -- normal-mode change so the modified marker shows up right away. Scheduled
  -- because the plugin's own handlers (which update cell.source) run after ours.
  vim.api.nvim_create_autocmd({ 'InsertLeave', 'TextChanged' }, {
    group = vim.api.nvim_create_augroup('IpynbRunModified', { clear = true }),
    callback = function(args)
      if not vim.b[args.buf].ipynb_is_edit_buffer then
        return
      end
      vim.schedule(function()
        local state = require('ipynb.state').get_from_edit_buf(args.buf)
        local edit = state and state.edit_state
        if edit and edit.buf == args.buf then
          visuals.render_all(state, { edit.cell_idx })
        end
      end)
    end,
  })

  -- A new or restarted kernel invalidates all run results.
  local kernel = require 'ipynb.kernel'
  for _, name in ipairs { 'connect', 'restart' } do
    local fn = kernel[name]
    kernel[name] = function(state, ...)
      runs[state] = nil
      return fn(state, ...)
    end
  end

  -- Clear the count when a cell is sent, like Jupyter's [*]: the new count may
  -- equal the old one (e.g. re-running in a fresh kernel), so only a cleared
  -- count tells us reliably when the kernel has started the cell. A cell that
  -- gets aborted by an interrupt ends up without a count, as in Jupyter.
  -- Cleared before the call, as execute() renders the cell as sent; restored
  -- if nothing was sent (no kernel, not a code cell).
  local execute = kernel.execute
  kernel.execute = function(state, cell_idx)
    local cell = state.cells[cell_idx]
    local count = cell and cell.execution_count
    if cell then
      cell.execution_count = nil
    end
    local sent = execute(state, cell_idx)
    if not sent and cell then
      cell.execution_count = count
    end
    return sent
  end
end

return M
