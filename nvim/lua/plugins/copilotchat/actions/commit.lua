local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local M = {}

local prompts = {
	Basic = 'Write a clear and concise "Basic" commit message for the selected changes.',
	WIP = 'Write a commit message indicating this is a work in progress "WIP" commit.',
	Merge = 'Write a commit message for merging the specified branches. \nSummarize the changes introduced by the "Merge".',
	["Squash Merge"] = 'Write a commit message for a "Squash Merge", summarizing all combined changes.',
}

local fallback_chat_title = {
	Basic = "Request to create basic commitments.",
	WIP = "Request to create WIP commitments.",
	Merge = "Request to Create Merge Commit.",
	["Squash Merge"] = "Request to Create Squash Merge Commit.",
}

local function build_sticky(commit_type, base_branch, commit_language)
	local git = nil
	local system = nil

	if commit_type == "Basic" or commit_type == "WIP" then
		git = "staged"
	elseif commit_type == "Merge" then
		system = "git diff " .. base_branch
	elseif commit_type == "Squash Merge" then
		local current_branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
		local show_commit_list_command = "git log "
			.. base_branch
			.. ".."
			.. current_branch
			.. ' --reverse --pretty="%an -> %s"'
		system = { "git diff " .. base_branch, show_commit_list_command }
	end

	return sticky.build({
		content_language = commit_language,
		file = { "commitlint.config.js", ".cz-config.js" },
		git = git,
		system = system,
	})
end

local build_system_prompt = function()
	return system_prompt.build({
		role = "commiter",
		character = "ai",
		guideline = { change_code = true, localization = true },
		specialties = "gitcommit",
		format = "commit",
	})
end

local function open_window(commit_type, base_branch, commit_language)
	local prompt = prompts[commit_type]

	local save_chat = function(response)
		chat_history.save(response, {
			used_prompt = prompt or fallback_chat_title[commit_type],
			tag = "Commit",
		})
	end

	window.open_float(prompt, {
		system_prompt = build_system_prompt(),
		sticky = build_sticky(commit_type, base_branch, commit_language),
		selection = false,
		callback = save_chat,
	})
end

local function on_commit_language_selected(commit_type, base_branch, language)
	if not language or language == "" then
		language = system_languages.default
	end
	open_window(commit_type, base_branch, language)
end

local function select_commit_language(commit_type, base_branch)
	vim.ui.select(system_languages.names, {
		prompt = "Select language> ",
	}, function(language)
		on_commit_language_selected(commit_type, base_branch, language)
	end)
end

local function input_base_branch(commit_type)
	vim.ui.input({ prompt = "Enter base branch> " }, function(input)
		if not input or input == "" then
			input = "main"
		end

		select_commit_language(commit_type, input)
	end)
end

local function select_base_branch(commit_type)
	vim.ui.select({ "main", "develop", "Other" }, {
		prompt = "Select base branch> ",
	}, function(selected_base_branch)
		if not selected_base_branch or selected_base_branch == "" then
			selected_base_branch = "main"
		end

		if selected_base_branch == "Other" then
			input_base_branch(commit_type)
		else
			select_commit_language(commit_type, selected_base_branch)
		end
	end)
end

M.execute = function()
	vim.ui.select({ "Basic", "WIP", "Merge", "Squash Merge" }, {
		prompt = "Select commit type> ",
	}, function(commit_type)
		if not commit_type or commit_type == "" then
			return
		end

		if commit_type == "Basic" or commit_type == "WIP" then
			select_commit_language(commit_type)
		elseif commit_type == "Merge" then
			select_base_branch(commit_type)
		elseif commit_type == "Squash Merge" then
			select_base_branch(commit_type)
		end
	end)
end

return M
