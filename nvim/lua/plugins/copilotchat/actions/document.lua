local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompts = {
	["Comment"] = "Add concise and clear comments to the selected code.",
	["Code Document"] = "Generate detailed documentation comments for the selected code, including its functionality, arguments, and return values.",
	["API Document"] = "Document the usage, arguments, return values, and important notes of the selected API in clear language.",
	["Developer Document"] = "Document the design intent, implementation details, and usage of the selected code in detail for developers.",
}

local note_lists = {
	["Comment"] = {
		"Consider not only the selected line but also related code and definitions from other files.",
		"Focus on clarity and brevity.",
		"Explain the intent and behavior, not just what the code does.",
	},
	["Code Document"] = {
		"Follow the language's documentation style (e.g., TSDoc for TypeScript).",
		"Describe the function/class purpose, arguments, return values, and typical usage.",
		"Reference related code context if available.",
	},
	["API Document"] = {
		"Include usage examples and describe input/output parameters.",
		"Document error cases and important constraints.",
		"Incorporate relevant context from related files or definitions.",
	},
	["Developer Document"] = {
		"Explain design intent and implementation details.",
		"Reference architectural context and related modules.",
		"Make the documentation suitable for README.md, pull requests, or new documentation files.",
	},
}

local tags = {
	["Comment"] = "Comment",
	["Code Document"] = "CodeDoc",
	["API Document"] = "APIDoc",
	["Developer Document"] = "DevDoc",
}

local build_prompt = function(action)
	local prompt = prompts[action]
	local note_list = note_lists[action]

	if not prompt or prompt == "" then
		return nil
	end

	if not note_list or #note_list == 0 then
		return prompt
	end

	return prompt .. "\n\n**Note**:\n\n- " .. table.concat(note_list, "\n- ")
end

local function build_system_prompt(action, restored_selection)
	local format = nil

	if action == "Developer Document" then
		format = "developer_document"
	end

	return system_prompt.build({
		role = "documenter",
		character = "ai",
		guideline = { change_code = true, localization = true },
		specialties = restored_selection and { restored_selection.filetype, "markdown" } or { "markdown" },
		question_focus = "selection",
		format = format,
	})
end

local function build_sticky(user_language, selected_files)
	return sticky.build({
		reply_language = system_languages.default,
		content_language = user_language,
		file = sticky.build_file_contexts(selected_files),
	})
end

local open_window = function(action, user_language, selected_files, restored_selection)
	local prompt = build_prompt(action)
	if not prompt then
		return
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = tags[action] })
		return response
	end

	local callback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(action, restored_selection),
		sticky = build_sticky(user_language, selected_files),
		selection = callback_selection,
		callback = save_chat,
	})
end

local function on_selected_files(target, user_language, selected_files)
	selection.restore(function(restored_selection)
		open_window(target, user_language, selected_files, restored_selection)
	end)
end

local function select_files(action, user_language)
	local callback = function(selected_files)
		on_selected_files(action, user_language, selected_files)
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

local select_user_language = function(actions)
	local ui_opts = { prompt = "Select language> " }
	vim.ui.select(system_languages.names, ui_opts, function(user_language)
		if not user_language or user_language == "" then
			user_language = system_languages.default
		end
		select_files(actions, user_language)
	end)
end

M.execute = function()
	local actions = { "Comment", "Code Document", "API Document", "Developer Document" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(actions, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		select_user_language(target)
	end)
end

return M
