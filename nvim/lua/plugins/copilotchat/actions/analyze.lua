local chat_select = require("CopilotChat.select")
local fzf_lua = require("fzf-lua")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local sticky = require("plugins.copilotchat.utils.sticky")
local window = require("plugins.copilotchat.utils.window")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

---@alias AnalyzeTarget "Variable"

---@class AnalyzeOpts
---@field selected_files table|nil
---@field restored_selection RestoreSelection

local prompts = {
	Variable = "Please analyze the provided file to track the selected variable and reveal details.",
	Function = "nalyze the selected function and provide comprehensive metrics using the exact format below with all quantitative data and detailed breakdowns.",
}

local check_lists = {
	Variable = {
		"Determine if the selection is a variable.",
		"Identify all types of operations on the variable: assignment, update, addition, subtraction, multiplication, division, and deletion.",
		"List all locations where the variable is used if there are multiple usages.",
	},
	Function = {
		"Follow the exact format provided in the prompt",
		"Use specific numbers for all metrics (0 if none, not 'N/A' or 'none')",
		"Keep descriptions under 100 characters each",
		"Use predefined values for categorized fields (read/write/update, for/while loops, etc.)",
		"Provide concrete analysis data rather than generic explanations",
		"Include line numbers and file references where applicable",
		"Create ASCII art for nesting structure visualization",
		"Categorize all findings into the specified sections with exact counts",
	},
}

local function build_prompt(target)
	local prompt = prompts[target]
	local check_list = check_lists[target]

	if not prompt or prompt == "" then
		return nil
	end

	if not check_list or #check_list == 0 then
		return prompt
	end

	return prompt .. "\n\n**Checklist**:\n- " .. table.concat(check_list, "\n- ")
end

local function build_sticky(target, opts)
	local file = {
		Variable = sticky.build_file_contexts(opts and opts.selected_files or nil),
		Function = sticky.build_file_contexts(opts and opts.selected_files or nil),
	}
	return sticky.build({
		reply_language = system_languages.default,
		file = file[target],
	})
end

local function build_system_prompt(target, restored_selection)
	local question_focus = {
		Variable = "selection",
		Function = "selection",
	}
	local format = {
		Variable = "analyze_variable",
		Function = "analyze_function",
	}

	return system_prompt.build({
		role = "teacher",
		character = "ai",
		guideline = { localization = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		question_focus = question_focus[target],
		format = format[target],
	})
end

--- Open the CopilotChat window for the given analyze action and selection.
---@param target AnalyzeTarget
---@param opts AnalyzeOpts
local function open_window(target, opts)
	local prompt = build_prompt(target)
	if not prompt then
		return
	end

	local callback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	local save_chat = function(response)
		chat_history.save(response, { used_prompt = prompt, tag = "Analyze" })
		return response
	end

	window.open_float(prompt, {
		system_prompt = build_system_prompt(target, opts and opts.restored_selection),
		sticky = build_sticky(target, opts),
		selection = callback_selection,
		callback = save_chat,
	})
end

--- Restore selection and open window for the given analyze action.
---@param target AnalyzeTarget
---@param opts AnalyzeOpts|nil
local function on_selected_files(target, opts)
	selection.restore(function(restored_selection)
		open_window(target, vim.tbl_extend("force", opts or {}, { restored_selection = restored_selection }))
	end)
end

local function select_files(target)
	local callback = function(selected_files)
		on_selected_files(target, { selected_files = selected_files })
	end
	fzf_lua.files({ prompt = "Files> ", actions = { ["default"] = callback }, multi = true })
end

local next = {
	Variable = select_files,
	Function = select_files,
}

M.execute = function()
	local targets = { "Variable", "Function" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		next[target](target)
	end)
end

return M
