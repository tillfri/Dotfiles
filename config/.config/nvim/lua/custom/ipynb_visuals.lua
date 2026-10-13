-- Make ipynb.nvim cells easier to scan: brighter borders and a full-width
-- background tint per cell (code and markdown cells get different tints).
--
-- The tint is drawn in our own namespace by wrapping ipynb.visuals.render_all,
-- which the plugin calls after every structural change. This relies on
-- internals (visuals.render_all, cells.get_cell_range), so re-check this file
-- when bumping the plugin's pinned commit.

local M = {}

local ns = vim.api.nvim_create_namespace 'ipynb_cell_tint'

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

function M.setup()
  set_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('IpynbVisuals', { clear = true }),
    callback = set_highlights,
  })

  local visuals = require 'ipynb.visuals'
  local render_all = visuals.render_all
  visuals.render_all = function(state, ...)
    render_all(state, ...)
    render_tint(state)
  end
end

return M
