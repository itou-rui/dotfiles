---@alias ExplainTarget "Code"|"File"

---@class ExplainOpts
---@field target ExplainTarget
---@field selected_files table|nil
---@field restored_selection RestoreSelection

local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local sticky = require("plugins.copilotchat.utils.sticky")
local window = require("plugins.copilotchat.utils.window")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

--- Get the prompt string for the given target.
---@param target ExplainTarget
---@return string
local function get_prompt(target)
	if target == "Code" then
		return "Write an explanation for the selected code as paragraphs of text."
	end
	if target == "File" then
		return "Write an explanation for the selected file as paragraphs of text."
	end
	return ""
end

--- Build sticky context for the given target and selected files.
---@param target ExplainTarget
---@param selected_files table|nil
---@return table
local build_sticky = function(target, selected_files)
	local file = nil

	if target == "Code" or target == "File" then
		file = sticky.build_file_contexts(selected_files)
	end

	return sticky.build({
		reply_language = system_languages.default,
		file = file,
	})
end

--- Build the system prompt for the given target and selection.
---@param target ExplainTarget
---@param restored_selection RestoreSelection
---@return string
local build_system_prompt = function(target, restored_selection)
	local question_focus = nil

	if target == "Code" or target == "File" then
		question_focus = "selection"
	end

	return system_prompt.build({
		role = "teacher",
		character = "ai",
		guideline = { localization = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		question_focus = question_focus,
		format = "explain",
	})
end

--- Open the CopilotChat window for the given target, selected files, and selection.
---@param target ExplainTarget
---@param selected_files table|nil
---@param restored_selection RestoreSelection
local function open_window(target, selected_files, restored_selection)
	local prompt = get_prompt(target)
	local stickies = build_sticky(target, selected_files)
	local system_instruction = build_system_prompt(target, restored_selection)

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Explain" })
		return response
	end

	local callback_selection = function(source)
		if target == "Code" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		if target == "File" then
			return chat_select.buffer(source)
		end
		return false
	end

	window.open_float(prompt, {
		system_prompt = system_instruction,
		sticky = stickies,
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Restore selection and open window for the given target and selected files.
---@param target ExplainTarget
---@param selected_files table|nil
local function on_selected_files(target, selected_files)
	if target == "Code" or target == "File" then
		selection.restore(function(restored_selection)
			open_window(target, selected_files, restored_selection)
		end)
	end
end

--- Prompt user to select files and handle selection for the given target.
---@param target ExplainTarget
local function select_files(target)
	local callback = function(selected_files)
		on_selected_files(target, selected_files)
	end

	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

M.execute = function()
	local targets = { "Code", "File" }
	local ui_opts = { prompt = "Select target> " }

	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		if target == "Code" or target == "File" then
			select_files(target)
		end
	end)
end

return M
