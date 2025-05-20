local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompt = [[
Fix the bug based on the given stack trace (`vim_register_0`).

**Note**:

- "Location of Occurrence" refers to where the error was thrown.
- "Root Cause" refers to the underlying cause that triggered the error.
  - If the cause is unclear, make a judgment based on the principles of "Best Practices."
  - If you followed specific rules or references, list the source (MDN, official TypeScript, etc.) in Source.
- Visually represent the bug occurrence flow using ASCII art.
- If there are multiple fixes, separate each into its own code block.
]]

local function build_sticky(target, selected_files)
	local file = nil
	local reply_language = nil
	local register = nil

	if target == "Bug" then
		file = sticky.build_file_contexts(selected_files)
		reply_language = system_languages.default
		register = "system_clipboard"
	end

	return sticky.build({
		file = file,
		reply_language = reply_language,
		register = register,
	})
end

local function build_system_prompt(target, restored_selection)
	local role = "assistant"
	local question_focus = nil
	local format = nil

	if target == "Bug" then
		role = "debugger"
		question_focus = "selection"
		format = "fix_bug"
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

local function open_window(target, selected_files, restored_selection)
	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "FixBug" })
		return response
	end

	local callback_selection = function(source)
		if target == "Bug" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(target, restored_selection),
		sticky = build_sticky(target, selected_files),
		selection = callback_selection,
		callback = save_chat,
	})
end

local function on_selected_files(target, selected_files)
	if target == "Bug" then
		selection.restore(function(restored_selection)
			open_window(target, selected_files, restored_selection)
		end)
	else
		open_window(target, selected_files)
	end
end

local function select_files(target)
	local callback = function(selected_files)
		on_selected_files(target, selected_files)
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

M.execute = function()
	local targets = { "Bug" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		if target == "Bug" then
			select_files(target)
		end
	end)
end

return M
