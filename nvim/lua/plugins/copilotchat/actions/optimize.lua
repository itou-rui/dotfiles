local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

---@alias OptimizeTarget "Code"|"Text"
---@class OptimizeOpts
---@field restored_selection RestoreSelection

local M = {}

local prompts = {
	Code = [[
Optimize the selected code for efficiency and maintainability.
Take into account related files and their interactions to achieve better optimization.
]],
	Text = [[
Improve the clarity, flow, and naturalness of the selected text.
!!! Follow the rules of **Content_Language**.
]],
}

local note_lists = {
	Code = {
		"Consider the related files for better optimization.",
		"Ensure the code is efficient and follows best practices.",
	},
	Text = {},
}

--- Builds the prompt string for the given optimization target.
--- Appends relevant notes if available.
---@param target OptimizeTarget Target type ("Code" or "Text").
---@return string|nil The constructed prompt, or nil if not available.
local function build_prompt(target)
	local prompt = prompts[target]
	local note_list = note_lists[target]
	if not prompt or prompt == "" then
		return nil
	end
	if not note_list or #note_list == 0 then
		return prompt
	end
	return prompt .. "\n\n**Note**:\n- " .. table.concat(note_list, "\n- ")
end

--- Constructs the system prompt for the optimization action.
--- Sets the role, guideline, and specialties based on the target and selection.
--- @param target OptimizeTarget Target type ("Code" or "Text").
--- @param restored_selection RestoreSelection|nil Selection context, may include filetype.
--- @return string The generated system prompt.
local function build_system_prompt(target, restored_selection)
	local role = {
		Code = "assistant",
		Text = "documenter",
	}
	local guideline = {
		Code = { change_code = true, localization = true, software_principles = true },
		Text = { change_code = true, localization = true },
	}
	local specialties = {
		Code = restored_selection and restored_selection.filetype or nil,
		Text = "documenter",
	}

	return system_prompt.build({
		role = role[target],
		character = "ai",
		guideline = guideline[target],
		question_focus = "selection",
		specialties = specialties[target],
	})
end

--- Builds sticky context information for the optimization window.
--- Includes related file contexts for code optimization.
--- @param target OptimizeTarget Target type ("Code" or "Text").
--- @param related_files table|nil List of related files for context.
--- @return table Sticky context configuration.
local function build_sticky(target, related_files)
	local file = {
		Code = sticky.build_file_contexts(related_files),
		Text = nil,
	}
	return sticky.build({
		reply_language = system_languages.default,
		file = file[target],
	})
end

--- Opens the optimization chat window with the constructed prompts and context.
--- Handles prompt construction, system prompt, sticky context, and response callback.
--- @param target OptimizeTarget Target type ("Code" or "Text").
--- @param opts table Options including restored_selection, related_files, etc.
local function open_window(target, opts)
	local prompt = build_prompt(target)
	if not prompt then
		return
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(target, opts and opts.restored_selection),
		sticky = build_sticky(target, opts and opts.related_files),
		selection = function(source)
			return chat_select.visual(source) or chat_select.buffer(source)
		end,
		callback = function(response)
			chat_history.save(response, { used_prompt = prompt, tag = "Optimize" })
			return response
		end,
	})
end

--- Restores the selection and opens the optimization window with selected files.
--- Used as a callback after file selection.
--- @param target OptimizeTarget Target type ("Code" or "Text").
--- @param opts table Options including selected_files.
local function on_selected_files(target, opts)
	selection.restore(function(restored_selection)
		open_window(target, { restored_selection = restored_selection, related_files = opts.selected_files })
	end)
end

--- Initiates file selection for code optimization using fzf-lua.
--- After selection, triggers the optimization window with the chosen files.
--- @param target OptimizeTarget Target type ("Code").
local function select_files(target)
	local callback = function(selected_files)
		on_selected_files(target, { selected_files = selected_files })
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

--- Table mapping optimization targets to their respective entry functions.
--- "Code" triggers file selection, "Text" opens the window directly.
local next = {
	Code = select_files,
	Text = function(target)
		open_window(target, {})
	end,
}

--- Entry point for the optimize action.
--- Prompts the user to select the optimization target ("Code" or "Text"),
--- then dispatches to the appropriate handler.
M.execute = function()
	local targets = { "Code", "Text" }
	vim.ui.select(targets, { prompt = "Select target> " }, function(target)
		if not target then
			return
		end
		next[target](target)
	end)
end

return M
