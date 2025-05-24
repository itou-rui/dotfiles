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
Please fix bugs in the selected code range, paying attention to the following points:

- Use the stack trace from `vim_register_0` as the primary clue.
- If the selected range does not provide enough information, note that "the user has not identified the cause," and in this case, use the provided information to the fullest extent to identify the cause.
- Since the provided file is likely related to the cause of the bug, also consider its definitions and references.
- Keep the scope of the fix to a minimum.

**Important**:

- If `vim_register_0` is not provided, respond only with `"**Copy the stack trace to the clipboard**"` and end this task.
- After correcting the bug, explain its location, root cause, and the reason for the correction. If necessary, conclude with an ASCII art diagram illustrating the bug's flow.
]],
}

--- Build sticky context for the given action and selected files.
---@param action ActionType
---@param selected_files table|nil
---@return table
local function build_sticky(action, selected_files)
	local file = {
		Bug = sticky.build_file_contexts(selected_files),
	}
	local register = {
		Bug = "system_clipboard",
	}

	return sticky.build({
		file = file[action],
		reply_language = system_languages.default,
		register = register[action],
	})
end

--- Build the system prompt for the given action and selection.
---@param action ActionType
---@param restored_selection RestoreSelection
---@return string
local function build_system_prompt(action, restored_selection)
	local role = {
		Bug = "assistant",
	}
	local question_focus = {
		Bug = "selection",
	}

	return system_prompt.build({
		role = role[action],
		character = "ai",
		guideline = { change_code = true, localization = true, software_principles = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		question_focus = question_focus[action],
	})
end

--- Open the CopilotChat window for the given action and options.
---@param action ActionType
---@param opts FixActionOpts
local function open_window(action, opts)
	local prompt = prompts[action]
	if not prompt then
		return
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Fix" })
		return response
	end

	local callback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
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

local next = {
	Bug = function(target)
		select_files(target, {})
	end,
}

M.execute = function()
	local actions = { "Bug" }
	local ui_opts = { prompt = "Select action> " }
	vim.ui.select(actions, ui_opts, function(action)
		if not action or action == "" then
			return
		end
		next[action](action)
	end)
end

return M
