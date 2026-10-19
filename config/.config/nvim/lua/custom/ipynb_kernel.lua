-- Keep ipynb.nvim kernels from being silently replaced or leaked.
--
-- Saving with :w from a cell's edit float writes the .ipynb through the edit
-- buffer, so Neovim keeps the old mtime for the notebook buffer. The next
-- timestamp check (focus regained, entering the buffer, :checktime, after :!)
-- sees a "changed" file and, with 'autoread', silently reloads it. A reload
-- rebuilds the notebook state from scratch: the running kernel is dropped (but
-- keeps running until Neovim exits) and the autostart in plugins/ipynb.lua
-- starts a fresh one, losing all variables.
--
-- So notebook buffers don't autoread: change notices for the notebook's own
-- writes are ignored, other changes ask before reloading. And a kernel is shut
-- down when its notebook state goes away (:e, :bd), instead of being leaked.
--
-- It also tracks kernel health for the statusline (M.status/M.color). The
-- plugin doesn't notice when the kernel process dies: the bridge stays up, the
-- notebook still says connected and cells queue forever. So while a kernel
-- runs, its process is looked up every few seconds with ps, which asks the OS
-- only and never sends the kernel anything. Idle/busy comes from the status
-- messages the plugin already receives.
--
-- This relies on internals (io.write_ipynb, state.remove, state.notebooks,
-- kernel.connect/restart/shutdown, state.kernel.job_id/connected/
-- execution_state/kernel_name, the bridge starting the kernel as its direct
-- child), so re-check this file when bumping the plugin's pinned commit.

local M = {}

---mtime of each notebook file as we last wrote it, by absolute path.
local written = {}

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and (stat.mtime.sec .. '.' .. stat.mtime.nsec)
end

---Health per notebook state: { job, misses, dead, checking }. misses:
---consecutive checks without a live kernel (a restart briefly has none);
---dead: kernel gone while connected.
local health = setmetatable({}, { __mode = 'k' })

local CHECK_MS = 3000
local poller

local function notebook_state()
  if not package.loaded['ipynb.state'] then
    return nil
  end
  local st = require 'ipynb.state'
  local buf = vim.api.nvim_get_current_buf()
  return st.get_by_facade(buf) or st.get_from_edit_buf(buf)
end

---Look for a live (non-zombie) child of the bridge, i.e. the kernel. A dead
---kernel stays a zombie until the bridge reaps it, which it never does, so
---kill(pid, 0) would still report it alive.
local function check_kernel(h)
  local ok, bridge = pcall(vim.fn.jobpid, h.job)
  if not ok then
    return
  end
  h.checking = true
  vim.system({ 'ps', '-A', '-o', 'ppid=,stat=' }, { text = true }, vim.schedule_wrap(function(res)
    h.checking = false
    for ppid, stat in (res.stdout or ''):gmatch '(%d+)%s+(%S+)' do
      if tonumber(ppid) == bridge and not stat:find 'Z' then
        h.misses, h.dead = 0, false
        return
      end
    end
    h.misses = h.misses + 1
    -- Several misses in a row, so a restart's gap isn't taken for a death.
    if h.misses >= 3 and not h.dead then
      h.dead = true
      vim.notify('Kernel died. :NotebookKernelRestart starts a new one.', vim.log.levels.ERROR)
    end
  end))
end

local function check()
  local any = false
  for _, state in pairs(require('ipynb.state').notebooks) do
    local kernel = state.kernel
    -- Keep polling while a kernel starts up; connect() returns before that.
    any = any or (kernel and kernel.job_id) ~= nil
    if kernel and kernel.job_id and kernel.connected then
      local h = health[state]
      if not h or h.job ~= kernel.job_id then
        h = { job = kernel.job_id, misses = 0 }
        health[state] = h
      end
      if not h.checking then
        check_kernel(h)
      end
    end
  end
  if not any then
    poller:stop()
  end
end

local function start_poller()
  poller = poller or vim.uv.new_timer()
  if not poller:is_active() then
    poller:start(0, CHECK_MS, vim.schedule_wrap(check))
  end
end

---Health of the current notebook: 'off' | 'starting' | 'idle' | 'busy' | 'dead',
---or nil outside notebooks.
local function health_of(state)
  local kernel = state.kernel
  if not (kernel and kernel.job_id) then
    return 'off'
  elseif not kernel.connected then
    return 'starting'
  elseif health[state] and health[state].dead then
    return 'dead'
  end
  return kernel.execution_state == 'busy' and 'busy' or 'idle'
end

local labels = {
  off = '󰒲 no kernel',
  starting = '󰔟 starting',
  idle = '󰄬 %s',
  busy = '󰦖 %s busy',
  dead = '󰅖 kernel died',
}
local colors = {
  off = 'Comment',
  starting = 'DiagnosticWarn',
  idle = 'DiagnosticOk',
  busy = 'DiagnosticWarn',
  dead = 'DiagnosticError',
}

---Statusline text for the current notebook (facade or cell edit buffer), '' elsewhere.
function M.status()
  local state = notebook_state()
  if not state then
    return ''
  end
  local name = state.kernel and state.kernel.kernel_name or 'kernel'
  return labels[health_of(state)]:format(name)
end

---Statusline color ({ fg = '#rrggbb' }) matching M.status().
function M.color()
  local state = notebook_state()
  local hl = vim.api.nvim_get_hl(0, { name = colors[state and health_of(state) or 'off'], link = false })
  return hl.fg and { fg = string.format('#%06x', hl.fg) } or nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup('IpynbKernel', { clear = true })

  local io_mod = require 'ipynb.io'
  local write_ipynb = io_mod.write_ipynb
  io_mod.write_ipynb = function(path, ...)
    local result = write_ipynb(path, ...)
    written[vim.fn.fnamemodify(path, ':p')] = mtime(path)
    return result
  end

  -- With 'autoread' Neovim reloads without firing FileChangedShell.
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'ipynb',
    group = group,
    callback = function(args)
      vim.bo[args.buf].autoread = false
    end,
  })

  vim.api.nvim_create_autocmd('FileChangedShell', {
    pattern = '*.ipynb',
    group = group,
    callback = function(args)
      local path = vim.fn.fnamemodify(args.file, ':p')
      local ours = written[path] and written[path] == mtime(path)
      -- '' = leave the buffer alone; 'ask' = the usual W11 prompt with (L)oad.
      vim.v.fcs_choice = ours and '' or 'ask'
    end,
  })

  local state_mod = require 'ipynb.state'
  local remove = state_mod.remove
  state_mod.remove = function(buf)
    local state = state_mod.notebooks[buf]
    if state and state.kernel and state.kernel.job_id then
      require('ipynb.kernel').shutdown(state)
    end
    return remove(buf)
  end

  -- Start watching on connect; a restart replaces the kernel process.
  local kernel = require 'ipynb.kernel'
  for _, name in ipairs { 'connect', 'restart' } do
    local fn = kernel[name]
    kernel[name] = function(state, ...)
      health[state] = nil
      local result = fn(state, ...)
      start_poller()
      return result
    end
  end
end

return M
