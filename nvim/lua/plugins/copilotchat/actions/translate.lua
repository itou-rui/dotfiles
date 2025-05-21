---@alias TranslateTarget "Text"|"Program"

---@class TranslateOpts
---@field target TranslateTarget
---@field language LanguageName
---@field restored_selection RestoreSelection
---@field selected_files table|nil

local fzf_lua = require("fzf-lua")
local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local programming_languages = {
	"typescript",
	"javascript",
	"python",
	"java",
	"c",
	"go",
	"kotlin",
	"rust",
	"css",
	"zsh",
}

local M = {}

--- Get the prompt string for the given target and language.
---@param target TranslateTarget
---@param language LanguageName
---@return string
local get_prompt = function(target, language)
	if target == "Text" then
		return "Localize the content of a given Selection with `" .. language .. "`."
	end
	if target == "Program" then
		return "Reproduce the complete contents of a given Selection in `" .. language .. "`."
	end
	return ""
end

--- Build sticky context for the given target, language, and selected files.
---@param target TranslateTarget
---@param language LanguageName
---@param selected_files table|nil
---@return table
local build_sticky = function(target, language, selected_files)
	local file = nil
	local reply_language = nil
	local content_language = nil

	if target == "Text" then
		content_language = language
	end

	if target == "Program" then
		file = sticky.build_file_contexts(selected_files)
		reply_language = system_languages.default
		content_language = system_languages.table.en
	end

	return sticky.build({
		file = file,
		reply_language = reply_language,
		content_language = content_language,
	})
end

--- Build the system prompt for the given target, language, and selection.
---@param target TranslateTarget
---@param language LanguageName
---@param restored_selection RestoreSelection
---@return string
local build_system_prompt = function(target, language, restored_selection)
	local role = "assistant"
	local question_focus = nil
	local specialties = nil

	if target == "Text" then
		question_focus = "selection"
	end

	if target == "Program" then
		question_focus = "selection"
		specialties = restored_selection and { restored_selection.filetype, language } or { language }
	end

	return system_prompt.build({
		role = role,
		character = "ai",
		guideline = { localization = true },
		specialties = specialties,
		question_focus = question_focus,
	})
end

--- Open the CopilotChat window for the given target, language, selection, and files.
---@param target TranslateTarget
---@param language LanguageName
---@param restored_selection RestoreSelection
---@param selected_files table|nil
local open_window = function(target, language, restored_selection, selected_files)
	local prompt = get_prompt(target, language)
	local stickies = build_sticky(target, language, selected_files)
	local system_instruction = build_system_prompt(target, language, restored_selection)

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Translate" })
		return response
	end

	local callback_selection = function(source)
		if target == "Text" or target == "Program" then
			return chat_select.visual(source) or chat_select.buffer(source)
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

--- Restore selection and open window for the given target, language, and files.
---@param target TranslateTarget
---@param programming_language string
---@param selected_files table|nil
local function on_selected_files(target, programming_language, selected_files)
	if target == "Text" or target == "Program" then
		selection.restore(function(restored_selection)
			open_window(target, programming_language, restored_selection, selected_files)
		end)
	end
	open_window(target, programming_language, nil, selected_files)
end

--- Prompt user to select files and handle selection for the given target and language.
---@param target TranslateTarget
---@param programming_language string
local select_files = function(target, programming_language)
	local callback = function(selected_files)
		on_selected_files(target, programming_language, selected_files)
	end

	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Prompt user to select a programming language and proceed to file selection.
---@param target TranslateTarget
local select_programming_language = function(target)
	local ui_opts = { prompt = "Select language> " }
	vim.ui.select(programming_languages, ui_opts, function(specialty)
		if not specialty or specialty == "" then
			specialty = nil
		end
		select_files(target, specialty)
	end)
end

--- Prompt user to select a user language and restore selection for the given target.
---@param target TranslateTarget
local function select_user_language(target)
	local ui_opts = { prompt = "Select Language> " }
	vim.ui.select(system_languages.names, ui_opts, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = system_languages.default
		end
		selection.restore(function(restored_selection)
			open_window(target, selected_language, restored_selection)
		end)
	end)
end

M.execute = function()
	local targets = { "Text", "Program" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		if target == "Text" then
			select_user_language(target)
		elseif target == "Program" then
			select_programming_language(target)
		end
	end)
end

return M
