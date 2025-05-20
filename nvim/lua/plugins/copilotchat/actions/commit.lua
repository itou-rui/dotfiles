local M = {}

local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local function build_system_sticky(commit_type, base_branch)
	if commit_type == "Basic" or commit_type == "WIP" then
		return nil
	end

	local current_branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD"))
	local show_diff_command = "git diff " .. base_branch

	if commit_type == "Merge" then
		return { show_diff_command }
	elseif commit_type == "Squash Merge" then
		local show_commit_list_command = "git log "
			.. base_branch
			.. ".."
			.. current_branch
			.. ' --reverse --pretty="%an -> %s"'

		return { show_diff_command, show_commit_list_command }
	end
end

local function build_git_sticky(commit_type)
	if commit_type == "Basic" or commit_type == "WIP" then
		return { "staged" }
	end
	return nil
end

local function get_prompt(commit_type)
	if commit_type == "Basic" then
		return 'Write a clear and concise "Basic" commit message for the selected changes.'
	elseif commit_type == "WIP" then
		return 'Write a commit message indicating this is a work in progress "WIP" commit.'
	elseif commit_type == "Merge" then
		return 'Write a commit message for merging the specified branches. \nSummarize the changes introduced by the "Merge".'
	elseif commit_type == "Squash Merge" then
		return 'Write a commit message for a "Squash Merge", summarizing all combined changes.'
	end
	return ""
end

local function fallback_chat_title(commit_type)
	if commit_type == "Basic" then
		return "Request to create basic commitments."
	elseif commit_type == "WIP" then
		return "Request to create WIP commitments."
	elseif commit_type == "Merge" then
		return "Request to Create Merge Commit."
	elseif commit_type == "Squash Merge" then
		return "Request to Create Squash Merge Commit."
	end
	return "Unknown Type of Commitment Creation Request."
end

local function open_window(commit_type, base_branch, commit_language)
	local prompt = get_prompt(commit_type)
	window.open_float(prompt, {
		system_prompt = system_prompt.build({
			role = "commiter",
			character = "ai",
			guideline = { change_code = true, localization = true },
			specialties = "gitcommit",
			format = "commit",
		}),
		sticky = sticky.build({
			content_language = commit_language,
			file = { "commitlint.config.js", ".cz-config.js" },
			git = build_git_sticky(commit_type),
			system = build_system_sticky(commit_type, base_branch),
		}),
		callback = function(response)
			chat_history.save(response, {
				used_prompt = prompt or fallback_chat_title(commit_type),
				tag = "Commit",
			})
			return response
		end,
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
