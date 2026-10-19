-- Look at an expression from the running ipynb.nvim kernel:
--   M.open(): dataframe-like expression in csvlens
--   M.full(): full, untruncated repr in a scrollable float
--
-- Connects as a second Jupyter client (same connection file as the plugin's
-- bridge) and evaluates the expression via a silent execute_request with
-- user_expressions: nothing is defined in the kernel, no history, no execution
-- count bump, and no output reaches the notebook.

local M = {}

M.python = vim.fn.expand '~/.venvs/monorepo-pytest/bin/python'
M.viewer = { 'csvlens' }
M.timeout = 30 -- seconds to wait for the kernel (it queues behind a running cell)
M.max_chars = 5000000 -- cap for M.full(), so a huge object doesn't flood nvim

-- argv: connection_file, expression, timeout, viewer...
local fetch_and_view = [[
import ast, queue, subprocess, sys
from jupyter_client import BlockingKernelClient

conn, expr, timeout, viewer = sys.argv[1], sys.argv[2], float(sys.argv[3]), sys.argv[4:]

kc = BlockingKernelClient(connection_file=conn)
kc.load_connection_file()
kc.start_channels(iopub=False, stdin=False, hb=False, control=False)
try:
    msg_id = kc.execute(
        "",
        silent=True,
        store_history=False,
        user_expressions={"x": f"__import__('pandas').DataFrame(({expr})).to_csv()"},
    )
    print(f"Fetching {expr} ...", file=sys.stderr, flush=True)
    while True:
        try:
            reply = kc.get_shell_msg(timeout=timeout)
        except queue.Empty:
            sys.exit(f"Kernel did not answer within {timeout:.0f}s (busy?)")
        if reply["parent_header"].get("msg_id") == msg_id:
            break
finally:
    kc.stop_channels()

res = reply["content"].get("user_expressions", {}).get("x", {})
if res.get("status") != "ok":
    sys.exit(f"{res.get('ename', 'Error')}: {res.get('evalue', reply['content'])}")

csv = ast.literal_eval(res["data"]["text/plain"])
sys.exit(subprocess.run(viewer, input=csv.encode()).returncode)
]]

-- Runs inside the kernel (exec'd into a throwaway namespace, so the user's
-- namespace stays untouched). Lifts pandas/numpy display limits only for the
-- duration of the render, which also covers DataFrames nested in containers.
local render_src = [[
def render(v, max_chars):
    import contextlib, pprint, sys
    t = type(v)
    info = [t.__qualname__ if t.__module__ == "builtins" else f"{t.__module__}.{t.__qualname__}"]
    for attr in ("shape", "dtype"):
        a = getattr(v, attr, None)
        if a is not None and not callable(a):
            info.append(f"{attr}={a}")
    if len(info) == 1:
        try:
            info.append(f"len={len(v)}")
        except Exception:
            pass
    pd, np = sys.modules.get("pandas"), sys.modules.get("numpy")
    with contextlib.ExitStack() as stack:
        if pd is not None:
            stack.enter_context(pd.option_context(
                "display.max_rows", None, "display.max_columns", None,
                "display.max_colwidth", None, "display.max_seq_items", None,
                "display.expand_frame_repr", False))
        if np is not None:
            stack.enter_context(np.printoptions(threshold=sys.maxsize, linewidth=200))
        if isinstance(v, str):
            body, ft = v, "text"
        elif pd is not None and isinstance(v, (pd.DataFrame, pd.Series)):
            body, ft = v.to_string(), "text"
        else:
            body, ft = pprint.pformat(v, width=120, compact=True, sort_dicts=False), "python"
            # Default repr ("<Foo object at 0x...>") says nothing; show the attributes.
            if body.startswith("<") and " object at 0x" in body and hasattr(v, "__dict__"):
                body += "\n\n" + pprint.pformat(vars(v), width=120, sort_dicts=False)
    return {"info": "  ".join(info), "body": body[:max_chars], "ft": ft,
            "truncated": len(body) > max_chars}
]]

-- argv: connection_file, expression, timeout, max_chars. Prints the render() dict as JSON.
local fetch_full = [[
import ast, json, queue, sys
from jupyter_client import BlockingKernelClient

conn, expr, timeout, max_chars, src = sys.argv[1], sys.argv[2], float(sys.argv[3]), int(sys.argv[4]), sys.argv[5]

kc = BlockingKernelClient(connection_file=conn)
kc.load_connection_file()
kc.start_channels(iopub=False, stdin=False, hb=False, control=False)
try:
    msg_id = kc.execute(
        "",
        silent=True,
        store_history=False,
        user_expressions={
            "x": f"(lambda v, ns={{}}: (exec({src!r}, ns), ns['render'](v, {max_chars}))[1])(({expr}))"
        },
    )
    while True:
        try:
            reply = kc.get_shell_msg(timeout=timeout)
        except queue.Empty:
            sys.exit(f"Kernel did not answer within {timeout:.0f}s (busy?)")
        if reply["parent_header"].get("msg_id") == msg_id:
            break
finally:
    kc.stop_channels()

res = reply["content"].get("user_expressions", {}).get("x", {})
if res.get("status") != "ok":
    sys.exit(f"{res.get('ename', 'Error')}: {res.get('evalue', reply['content'])}")

json.dump(ast.literal_eval(res["data"]["text/plain"]), sys.stdout)
]]

local function notebook_state()
  local st = require 'ipynb.state'
  return st.get() or st.get_from_edit_buf(vim.api.nvim_get_current_buf())
end

-- The bridge starts the kernel as its direct child with `-f <connection file>`.
local function connection_file(state)
  local job = state.kernel and state.kernel.job_id
  if not job or not state.kernel.connected then
    return nil, 'No kernel running for this notebook'
  end
  local ok, bridge_pid = pcall(vim.fn.jobpid, job)
  if not ok then
    return nil, 'Kernel bridge is not running'
  end
  local children = vim.system({ 'pgrep', '-P', tostring(bridge_pid) }, { text = true }):wait().stdout or ''
  for pid in children:gmatch '%d+' do
    local args = vim.system({ 'ps', '-o', 'args=', '-p', pid }, { text = true }):wait().stdout or ''
    local file = args:match '%-f%s+(%S+%.json)'
    if file then
      return file
    end
  end
  return nil, 'Could not find the kernel connection file (kernel not started by ipynb.nvim?)'
end

local function selected_expr()
  local mode = vim.fn.mode()
  if mode == 'v' or mode == 'V' or mode == '\22' then
    local lines = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = mode })
    vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
    return vim.trim(table.concat(lines, ' '))
  end
  return vim.fn.expand '<cexpr>'
end

-- Connection file and expression to evaluate, or nil (after notifying why).
local function target()
  local state = notebook_state()
  if not state then
    return vim.notify('Not in an ipynb.nvim notebook', vim.log.levels.WARN)
  end
  local conn, err = connection_file(state)
  if not conn then
    return vim.notify(err, vim.log.levels.WARN)
  end
  local expr = selected_expr()
  if expr == '' then
    return vim.notify('No expression under cursor', vim.log.levels.WARN)
  end
  return conn, expr
end

function M.full()
  local conn, expr = target()
  if not conn then
    return
  end

  local cmd = { M.python, '-c', fetch_full, conn, expr, tostring(M.timeout), tostring(M.max_chars), render_src }
  vim.system(cmd, { text = true }, function(res)
    vim.schedule(function()
      local ok, data = pcall(vim.json.decode, res.stdout or '')
      if res.code ~= 0 or not ok then
        local msg = vim.trim(res.stderr or '')
        return vim.notify(msg ~= '' and msg or 'Failed to fetch value', vim.log.levels.ERROR, { title = 'ipynb full: ' .. expr })
      end

      local lines = vim.split(data.body, '\n', { plain = true })
      if data.truncated then
        table.insert(lines, ('... truncated at %d chars (see M.max_chars)'):format(M.max_chars))
      end
      Snacks.win {
        text = lines,
        ft = data.ft,
        width = 0.9,
        height = 0.9,
        border = 'rounded',
        title = ' ' .. expr .. ' ',
        footer = ' ' .. data.info .. ' ',
        bo = { modifiable = false },
        wo = { wrap = false, cursorline = true },
        keys = { q = 'close', ['<Esc>'] = 'close' },
      }
    end)
  end)
end

function M.open()
  local conn, expr = target()
  if not conn then
    return
  end

  local cmd = { M.python, '-c', fetch_and_view, conn, expr, tostring(M.timeout) }
  vim.list_extend(cmd, M.viewer)

  local term = Snacks.terminal.open(cmd, {
    interactive = true,
    auto_close = false,
    win = { position = 'float', width = 0.95, height = 0.9, border = 'rounded', title = ' ' .. expr .. ' ' },
  })
  vim.api.nvim_create_autocmd('TermClose', {
    buffer = term.buf,
    once = true,
    callback = function()
      local code = vim.v.event.status
      vim.schedule(function()
        if code ~= 0 and vim.api.nvim_buf_is_valid(term.buf) then
          local lines = vim.tbl_filter(function(l)
            return l ~= '' and not l:match '^Fetching '
          end, vim.api.nvim_buf_get_lines(term.buf, 0, -1, false))
          vim.notify(table.concat(lines, '\n'), vim.log.levels.ERROR, { title = 'ipynb lens: ' .. expr })
        end
        term:close()
      end)
    end,
  })
end

return M
