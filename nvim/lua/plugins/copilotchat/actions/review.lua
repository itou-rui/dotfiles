---@alias ReviewTarget "Code"|"Spelling"
---@class ReviewOpts
---@field restored_selection RestoreSelection

local chat_select = require("CopilotChat.select")
local copilot_chat_ns = vim.api.nvim_create_namespace("copilot-chat-diagnostics")
local diagnostics_parser = require("plugins.copilotchat.utils.diagnostics")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

local prompts = {
	Code = [[
Review the code for the **selection**.
Multiple issues on one line should be separated by semicolons
End with: "**`To clear buffer highlights, please ask a different question`**"
]],
	Spelling = [[
Review the spelling for the **selection**.,
Multiple issues on one line should be separated by semicolons
End with: "**`To clear buffer highlights, please ask a different question`**"
]],
}

local check_lists = {
	Code = {
		"Unclear or non-conventional naming",
		"Comment quality (missing or unnecessary)",
		"Complex expressions needing simplification",
		"Deep nesting or complex control flow",
		"Inconsistent style or formatting",
		"Code duplication or redundancy",
		"Potential performance issues",
		"Error handling gaps",
		"Security concerns",
		"Breaking of SOLID principles",
	},
	Spelling = {
		"Spelling mistakes",
		"Grammatical errors",
		"Awkward or unclear phrasing",
		"Inconsistent terminology or style",
		"Tone or language that may reduce clarity or professionalism",
	},
}

--- Build the prompt string for the given review action.
---@param target ReviewTarget
---@return string|nil
local build_prompt = function(target)
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

--- Build the system prompt for the given review action and selection.
---@param target ReviewTarget
---@param restored_selection RestoreSelection
---@return string
local build_system_prompt = function(target, restored_selection)
	return system_prompt.build({
		role = "reviewer",
		character = "ai",
		guideline = { localization = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		format = "review",
	})
end

--- Build sticky context for review.
---@return table
local function build_sticky()
	return sticky.build({
		reply_language = system_languages.default,
	})
end

--- Open the CopilotChat window for the given review action and selection.
---@param target ReviewTarget
---@param restored_selection RestoreSelection
local function open_window(target, restored_selection)
	local prompt = build_prompt(target)
	if not prompt then
		return
	end

	local callback_selection = function(source)
		if target == "Code" or target == "Spelling" then
			return chat_select.visual(source) or chat_select.buffer(source)
		end
		return false
	end

	local function set_diagnostic(response, source)
		local diagnostics = diagnostics_parser.parse_review_response("Copilot Review", response)
		vim.diagnostic.set(copilot_chat_ns, source.bufnr, diagnostics)
	end

	window.open_vertical(prompt, {
		system_prompt = build_system_prompt(target, restored_selection),
		sticky = build_sticky(),
		selection = callback_selection,
		callback = function(response, source)
			chat_history.save(response, { used_prompt = prompt, tag = "Review" .. target })
			set_diagnostic(response, source)
			return response
		end,
	})
end

--- Restore selection and open window for the given review action.
---@param target ReviewTarget
local function on_selected_target(target)
	selection.restore(function(restored_selection)
		open_window(target, restored_selection)
	end)
end

M.execute = function()
	local targets = { "Code", "Spelling" }
	local ui_opts = { prompt = "Select target> " }
	vim.ui.select(targets, ui_opts, function(target)
		if not target or target == "" then
			return
		end
		on_selected_target(target)
	end)
end

return M
