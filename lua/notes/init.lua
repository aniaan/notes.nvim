local M = {}
local H = {}

local did_setup = false

M.config = {
	notes_dir = nil,
	default_extension = "md",
	template = nil,
	date_format = "%Y-%m-%d",
	keymaps = {
		search = "<leader>ns",
		create = "<leader>nc",
		list = "<leader>nl",
	},
}

H.default_config = vim.deepcopy(M.config)

M.setup = function(config)
	if did_setup then
		return
	end
	config = H.setup_config(config)
	H.apply_config(config)
	H.create_user_commands()
  H.set_keymap()
	did_setup = true
end

M.list_notes = function()
	if pcall(require, "fzf-lua") then
		require("fzf-lua").files({ cwd = M.config.notes_dir })
	else
		vim.notify("fzf-lua.nvim is required to list notes", vim.log.levels.ERROR)
	end
end

M.search_notes = function()
	if pcall(require, "fzf-lua") then
		require("fzf-lua").live_grep({ cwd = M.config.notes_dir })
	else
		vim.notify("fzf-lua.nvim is required to search notes", vim.log.levels.ERROR)
	end
end

M.create_notes = function(opts)
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

	local filepath = vim.fs.join(M.config.notes_dir, filename)

	if vim.fn.filereadable(filepath) == 1 then
		local overwrite = vim.fn.input(string.format("File '%s' exists. Overwrite? (y/N): ", filename))
		if not overwrite:lower():match("^y") then
			print("Aborted")
			return
		end
	end

	local mode = opts.mode or "vsplit"
	local cmd = ({
		split = "split",
		vsplit = "vsplit",
		tabedit = "tabedit",
		edit = "edit",
	})[mode] or "vsplit"

	vim.cmd(cmd .. " " .. vim.fn.fnameescape(filepath))

	-- local buf = vim.api.nvim_get_current_buf()
	-- if vim.fn.filereadable(filepath) == 0 then
	-- 	vim.api.nvim_buf_set_lines(buf, 0, -1, false, H.get_template_content())
	-- end
end

H.generate_filename = function()
	local prefix = "Untitled-"
	local files = vim.fn.glob(vim.fs.join(M.config.notes_dir, prefix .. "*"), true, true)

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

H.setup_config = function(config)
	config = vim.tbl_deep_extend("force", H.default_config, config or {})
	if not config.notes_dir or config.notes_dir == "" then
		error("notes_dir must be set")
	end
	config.notes_dir = vim.fn.expand(config.notes_dir)

	if vim.fn.isdirectory(config.notes_dir) == 0 then
		vim.fn.mkdir(config.notes_dir, "p")
	end

	return config
end

H.apply_config = function(config)
	M.config = config
end

H.create_user_commands = function()
	vim.api.nvim_create_user_command("NotesList", M.list_notes, {})
	vim.api.nvim_create_user_command("NotesSearch", M.search_notes, {})
	vim.api.nvim_create_user_command("NotesCreate", function(opts)
		M.create_notes({ mode = opts.args })
	end, {
		nargs = "?",
		complete = function()
			return { "edit", "split", "vsplit", "tabedit" }
		end,
	})
end

H.set_keymap = function()
	local keymaps = M.config.keymaps
	vim.keymap.set("n", keymaps.create, M.create_notes, { noremap = true, silent = true, desc = "Create Notes" })
	vim.keymap.set("n", keymaps.search, M.search_notes, { noremap = true, silent = true, desc = "Search Notes" })
	vim.keymap.set("n", keymaps.list, M.list_notes, { noremap = true, silent = true, desc = "List Notes" })
end

-- H.get_template_content = function()
-- 	if not M.config.template then
-- 		return {}
-- 	end
--
-- 	local content
-- 	if type(M.config.template) == "string" then
-- 		content = M.config.template
-- 	elseif type(M.config.template) == "table" and M.config.template.file then
-- 		local path = vim.fn.expand(M.config.template.file)
-- 		if vim.fn.filereadable(path) == 1 then
-- 			content = table.concat(vim.fn.readfile(path), "\n")
-- 		end
-- 	end
--
-- 	if content then
-- 		content = content:gsub("%%date%%", os.date(M.config.date_format))
-- 		return vim.split(content, "\n")
-- 	end
-- 	return {}
-- end

return M
