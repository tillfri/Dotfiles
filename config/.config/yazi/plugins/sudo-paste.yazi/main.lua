--- @since 26.8.15

-- Falls back to `sudo cp`/`sudo mv` when the destination directory isn't
-- writable, after confirming with the user. Otherwise behaves exactly like
-- the built-in `paste`.

local function fail(s, ...)
	ya.notify { title = "Sudo Paste", content = string.format(s, ...), level = "error", timeout = 5 }
end

local get_state = ya.sync(function()
	local urls = {}
	for _, u in pairs(cx.yanked) do
		urls[#urls + 1] = tostring(u.url or u)
	end
	return urls, cx.yanked.is_cut, tostring(cx.active.current.cwd)
end)

local function writable(dir)
	local status = Command("test"):arg({ "-w", dir }):status()
	return status and status.success or false
end

return {
	entry = function(_, job)
		job = type(job) == "string" and { args = { job } } or job
		local force = job.args[1] == "force"

		local urls, cut, cwd = get_state()

		if #urls == 0 or writable(cwd) then
			return ya.emit("paste", { force = force })
		end

		local value, event = ya.input {
			title = string.format(
				"No write access to `%s`. Sudo %s %d item(s)? [y/N]:",
				cwd,
				cut and "move" or "copy",
				#urls
			),
			pos = { "top-center", y = 3, w = 60 },
		}
		if not value or event ~= 1 or value:lower() ~= "y" then
			return
		end

		local sudo = require(".sudo")
		local program = cut and "mv" or "cp"
		local args = cut and {} or { "-a" }
		for _, u in ipairs(urls) do
			args[#args + 1] = u
		end
		args[#args + 1] = cwd

		local out, err = sudo.run_with_sudo(program, args)
		if not out then
			fail("Failed to run sudo %s: %s", program, err)
		elseif not out.status.success then
			fail("Sudo %s failed:\n%s", program, out.stderr)
		end
	end,
}
