---@alias TranslateTarget "Text"|"Program"

---@class TranslateOpts
---@field programming_language string|nil
---@field user_language LanguageName|nil
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

local prompts = {
	Text = "Localize the content of a given Selection with `%s`.",
	Program = "Reproduce the complete contents of a given Selection in `%s`.",
}

local note_lists = {
	Text = {
		"Please translate considering the context and use native expressions in the target language, not just a literal translation.",
		"Do not change the original meaning of the text.",
	},
	Program = {
		"Preserve the internal structure between the source and translated code (e.g., variable names, arguments).",
		"Ensure the translated code behaves identically to the original.",
		"Reproduce any features or dependencies present in the original code.",
		"Retain all comments and documentation from the original code in the translation.",
	},
}

--- Get the prompt string for the given target and language.
---@param target TranslateTarget
---@param opts TranslateOpts
---@return string|nil
local build_prompt = function(target, opts)
	local prompt = prompts[target]
	local note_list = note_lists[target]

	if not prompt or prompt == "" then
		return nil
	end

	if not note_list or #note_list == 0 then
		return prompt
	end

	if target == "Text" then
		prompt = prompt:format(opts.user_language)
	end
	if target == "Program" then
		prompt = prompt:format(opts.programming_language)
	end

	return prompt .. "\n\n**Note**:\n- " .. table.concat(note_list, "\n- ")
end

--- Build sticky context for the given target, language, and selected files.
--- @param target TranslateTarget
--- @param opts TranslateOpts
--- @return table
local build_sticky = function(target, opts)
	local file = nil

	if target == "Program" then
		file = sticky.build_file_contexts(opts.selected_files)
	end

	return sticky.build({
		file = file,
		reply_language = system_languages.default,
	})
end

--- Build the system prompt for the given target, language, and selection.
--- @param target TranslateTarget
--- @param opts TranslateOpts
--- @return string
local build_system_prompt = function(target, opts)
	local specialties = {
		Text = nil,
		Program = opts.restored_selection and { opts.restored_selection.filetype, opts.programming_language }
			or { opts.programming_language },
	}

	return system_prompt.build({
		role = "assistant",
		character = "ai",
		guideline = { localization = true },
		specialties = specialties[target],
		question_focus = "selection",
	})
end

--- Open the CopilotChat window for the given options.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local open_window = function(target, opts)
	local prompt = build_prompt(target, opts)
	if not prompt then
		return
	end

	local stickies = build_sticky(target, opts)
	local system_instruction = build_system_prompt(target, opts)

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

--- @param target TranslateTarget
--- @param opts TranslateOpts
local function selection_restore(target, opts)
	selection.restore(function(restored_selection)
		opts = vim.tbl_extend("force", opts, { target = target, restored_selection = restored_selection })
		open_window(target, opts)
	end)
end

--- Restore selection and open window for the given options.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local function on_selected_files(target, opts)
	selection_restore(target, opts)
end

--- Prompt user to select files and handle selection for the given target and language.
--- @param target TranslateTarget
--- @param opts TranslateOpts
local select_files = function(target, opts)
	local callback = function(selected_files)
		on_selected_files(target, vim.tbl_extend("force", opts, { selected_files = selected_files }))
	end
	fzf_lua.files({ prompt = "Related Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Prompt user to select a programming language and proceed to file selection.
--- @param target TranslateTarget
local select_programming_language = function(target)
	local ui_opts = { prompt = "Select language> " }
	vim.ui.select(programming_languages, ui_opts, function(specialty)
		if not specialty or specialty == "" then
			specialty = nil
		end
		local opts = vim.tbl_extend("force", {}, { programming_language = specialty })
		select_files(target, opts)
	end)
end

--- Prompt user to select a user language and restore selection for the given target.
--- @param target TranslateTarget
local function select_user_language(target)
	local ui_opts = { prompt = "Select Language> " }
	vim.ui.select(system_languages.names, ui_opts, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = system_languages.default
		end
		selection.restore(function(restored_selection)
			local opts = vim.tbl_extend("force", {}, {
				user_language = selected_language,
				restored_selection = restored_selection,
			})
			open_window(target, opts)
		end)
	end)
end

local next = {
	Text = select_user_language,
	Program = select_programming_language,
}

M.execute = function()
	local targets = { "Text", "Program" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		next[target](target)
	end)
end

return M
