---@alias ActionType "Bug"|"Issues"
---@class FixActionOpts
---@field selected_files table|nil
---@field input_issues string|nil
---@field restored_selection RestoreSelection

local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompts = {
	Bug = [[
Use the stack trace from `vim_register_0` and the selected code to identify the root cause of the bug.
Propose a clear and minimal fix, and explain its intent and behavior.
If needed, consider related code and definitions within the selected files.
]],
	Issues = [[

]],
}

local note_lists = {
	Bug = {
		"Always use the stack trace from `vim_register_0` as the primary clue.",
		"Focus on the selected code, but also consider related functions, calls, or definitions from the same files.",
		"Your fix should be minimal, clear, and easy to understand.",
		"Explain the **intent and effect** of your fix, not just what it does.",
		"If `vim_register_0` does not contain a stack trace or relevant error, respond with: **Please copy the stack trace or error message**.",
		"If a required file context is missing based on the stack trace or selection, respond with: `> #file:<file_path>` and include only the necessary missing context.",
	},
	Issues = {},
}

local tags = {
	Bug = "FixBug",
	Issues = "FixIssues",
}

--- Build the prompt string for the given action.
---@param action ActionType
---@param input_issues string|nil
---@return string|nil
local function build_prompt(action, input_issues)
	local prompt = prompts[action]
	local note_list = note_lists[action]

	if not prompt or prompt == "" then
		return nil
	end

	if not note_list or #note_list == 0 then
		return prompt
	end

	return prompt .. "\n\n**Note**:\n- " .. table.concat(note_list, "\n- ")
end

--- Build sticky context for the given action and selected files.
---@param action ActionType
---@param selected_files table|nil
---@return table
local function build_sticky(action, selected_files)
	local file = nil
	local reply_language = nil
	local register = nil

	if action == "Bug" then
		file = sticky.build_file_contexts(selected_files)
		reply_language = system_languages.default
		register = "system_clipboard"
	end

	if action == "Issues" then
		file = sticky.build_file_contexts(selected_files)
		reply_language = system_languages.default
	end

	return sticky.build({
		file = file,
		reply_language = reply_language,
		register = register,
	})
end

--- Build the system prompt for the given action and selection.
---@param action ActionType
---@param restored_selection RestoreSelection
---@return string
local function build_system_prompt(action, restored_selection)
	local role = "assistant"
	local question_focus = nil
	local format = nil

	if action == "Bug" then
		role = "debugger"
		question_focus = "selection"
		format = "fix_bug"
	end

	if action == "Issues" then
		role = "assistant"
		question_focus = "selection"
	end

	return system_prompt.build({
		role = role,
		character = "ai",
		guideline = { change_code = true, localization = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		question_focus = question_focus,
		format = format,
	})
end

--- Open the CopilotChat window for the given action and options.
---@param action ActionType
---@param opts FixActionOpts
local function open_window(action, opts)
	local prompt = build_prompt(action, opts.input_issues)
	if not prompt then
		return
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = tags[action] })
		return response
	end

	local callback_selection = function(source)
		if action == "Bug" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(action, opts.restored_selection),
		sticky = build_sticky(action, opts.selected_files),
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Restore selection and open window for the given action and options.
---@param action ActionType
---@param opts FixActionOpts
local function on_selected_files(action, opts)
	selection.restore(function(restored_selection)
		open_window(action, {
			selected_files = opts.selected_files,
			input_issues = opts.input_issues,
			restored_selection = restored_selection,
		})
	end)
end

--- Prompt user to select files and handle selection for the given action and options.
---@param action ActionType
---@param opts FixActionOpts
local function select_files(action, opts)
	opts = opts or {}
	local callback = function(selected_files)
		on_selected_files(action, {
			selected_files = selected_files,
			input_issues = opts.input_issues,
		})
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Prompt user for issues input and proceed to file selection for the given action.
---@param action ActionType
local input_issues = function(action)
	local ui_opts = { prompt = "Write issues> " }
	vim.ui.input(ui_opts, function(issues)
		if not issues or issues == "" then
			return
		end
		select_files(action, { input_issues = issues })
	end)
end

local next = {
	Bug = select_files,
	Issues = input_issues,
}

M.execute = function()
	local actions = { "Bug", "Issues" }
	local ui_opts = { prompt = "Select action> " }
	vim.ui.select(actions, ui_opts, function(action)
		if not action or action == "" then
			return
		end
		next[action](action)
	end)
end

return M
