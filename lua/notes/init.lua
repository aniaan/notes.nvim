local M = {}
local H = {}

local did_setup = false

M.config = {
	notes_dir = nil,
	default_extension = "md",
}

H.default_config = vim.deepcopy(M.config)

M.setup = function(config)
	if did_setup then
		return
	end
	config = H.setup_config(config)
	H.apply_config(config)
	H.create_user_commands()
	did_setup = true
end

M.list_notes = function()
	H.ensure_setup()
	if pcall(require, "snacks.picker") then
		require("snacks.picker").files({ cwd = M.config.notes_dir, hidden = true })
	else
		vim.notify("snacks.picker is required to list notes", vim.log.levels.ERROR)
	end
end

M.search_notes = function()
	H.ensure_setup()
	if pcall(require, "snacks.picker") then
    require("snacks.picker").grep({ cwd = M.config.notes_dir })
	else
		vim.notify("snacks.picker is required to search notes", vim.log.levels.ERROR)
	end
end

M.create_note = function(opts)
	H.ensure_setup()
	opts = opts or {}
	local filename = vim.fn.input("Filename: ")

	if filename == "" then
		filename = H.generate_filename()
	else
		local has_extension = filename:match("%..+$")
		if not has_extension then
			filename = filename .. "." .. M.config.default_extension
		end
	end

	local filepath = M.config.notes_dir .. "/" .. filename

	if vim.fn.filereadable(filepath) == 1 then
		local overwrite = vim.fn.input(string.format("File '%s' exists. Overwrite? (y/N): ", filename))
		if not overwrite:lower():match("^y") then
			return
		end
	end

	local mode = opts.mode or "edit"
	local cmd = ({
		split = "split",
		vsplit = "vsplit",
		tabedit = "tabedit",
		edit = "edit",
	})[mode] or "edit"

	vim.cmd(cmd .. " " .. vim.fn.fnameescape(filepath))
end

H.generate_filename = function()
	local prefix = "Untitled-"
	local files = vim.fn.glob(M.config.notes_dir .. "/" .. prefix .. "*" .. M.config.default_extension, true, true)

	local existing_numbers = {}
	for _, file in ipairs(files) do
		local filename = vim.fn.fnamemodify(file, ":t:r") -- Extract filename without extension
		local number_str = string.sub(filename, #prefix + 1) -- Extract the number part

		if number_str ~= "" then
			local number = tonumber(number_str)
			if number then
				table.insert(existing_numbers, number)
			end
		end
	end

	table.sort(existing_numbers)

	local next_number = nil
	if #existing_numbers > 0 then
		-- Find the next available number
		for i = 1, #existing_numbers do
			if existing_numbers[i] ~= i then
				next_number = i
				break
			end
		end
		if next_number == nil then
			next_number = #existing_numbers + 1
		end
	else
		next_number = 1
	end

	return string.format("%s%d.%s", prefix, next_number, M.config.default_extension)
end

M.push_notes = function()
	H.ensure_setup()
	H.ensure_git_repo()

	H.git_add(M.config.notes_dir)
	H.git_commit(M.config.notes_dir, "sync notes")
	H.git_push(M.config.notes_dir)
end

M.pull_notes = function()
	H.ensure_setup()
	H.ensure_git_repo()

	local pull_cmd = "git -C " .. M.config.notes_dir .. " pull --rebase 2>&1"
	local output = vim.fn.system(pull_cmd)

	if vim.v.shell_error ~= 0 then
		H.error("Git pull --rebase failed, rebase aborted. Please sync manually.\n" .. output)
	end
end

H.setup_config = function(config)
	config = vim.tbl_deep_extend("force", H.default_config, config or {})
	if config.notes_dir == nil or config.notes_dir == "" then
		H.error("notes_dir must be set")
	end
	config.notes_dir = vim.fn.expand(config.notes_dir)

	if vim.fn.isdirectory(config.notes_dir) == 0 then
		H.error("notes_dir must be exists")
	end

	return config
end

H.error = function(msg)
	error("(notes.nvim) " .. msg, 0)
end

H.ensure_setup = function()
	if not did_setup then
		H.error("Please call setup() before using this plugin")
	end
end

H.ensure_git = function()
	if vim.fn.executable("git") == 0 then
		H.error("Git is required to use this plugin")
	end
end

H.is_git_repo = function(dir)
	local cmd = "git -C " .. dir .. " remote get-url origin 2> /dev/null"
	vim.fn.system(cmd)
	return vim.v.shell_error == 0
end

H.ensure_git_repo = function()
	if not H.is_git_repo(M.config.notes_dir) then
		H.error("Not a git repository")
	end
end

H.git_add = function(dir)
	local add_cmd = "git -C " .. dir .. " add ."
	vim.fn.system(add_cmd)
	if vim.v.shell_error ~= 0 then
		H.error("Git add failed")
	end
end

H.git_commit = function(dir, message)
	local commit_cmd = string.format("git -C %s commit -m %s", dir, vim.fn.shellescape(message))
	vim.fn.system(commit_cmd)
	if vim.v.shell_error ~= 0 then
		H.error("Git commit failed")
	end
end

H.git_push = function(dir)
	local push_cmd = "git -C " .. dir .. " push 2>&1"
	vim.fn.system(push_cmd)
	if vim.v.shell_error ~= 0 then
		H.error("Git push failed")
	end
end

H.apply_config = function(config)
	M.config = config
end

H.create_user_commands = function()
	vim.api.nvim_create_user_command("NotesList", M.list_notes, {})
	vim.api.nvim_create_user_command("NotesSearch", M.search_notes, {})
	vim.api.nvim_create_user_command("NotesCreate", function(opts)
		M.create_note({ mode = opts.args })
	end, {
		nargs = "?",
		complete = function()
			return { "edit", "split", "vsplit", "tabedit" }
		end,
	})
	-- notes pull and notes push
	vim.api.nvim_create_user_command("NotesPull", M.pull_notes, {})
	vim.api.nvim_create_user_command("NotesPush", M.push_notes, {})
end

return M
