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

local code_prompt = [[
Review the code for the **selection**.

**Check for**:

- Unclear or non-conventional naming
- Comment quality (missing or unnecessary)
- Complex expressions needing simplification
- Deep nesting or complex control flow
- Inconsistent style or formatting
- Code duplication or redundancy
- Potential performance issues
- Error handling gaps
- Security concerns
- Breaking of SOLID principles
]]

local spelling_prompt = [[
Review the spelling for the **selection**.

**Check for**:

- Spelling mistakes
- Grammatical errors
- Awkward or unclear phrasing
- Inconsistent terminology or style
- Tone or language that may reduce clarity or professionalism
]]

local function get_prompt(target)
	if target == "Code" then
		return code_prompt
	end
	if target == "Spelling" then
		return spelling_prompt
	end
	return ""
end

local build_system_prompt = function(target, restored_selection)
	return system_prompt.build({
		role = "assistant",
		character = "ai",
		guideline = { localization = true },
		specialties = restored_selection and restored_selection.filetype or nil,
		format = "review",
	})
end

local function build_sticky()
	return sticky.build({
		reply_language = system_languages.default,
	})
end

local function open_window(target, restored_selection)
	local prompt = get_prompt(target)

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
			chat_history.save(response, { used_prompt = prompt, tag = "Review" })
			set_diagnostic(response, source)
			return response
		end,
	})
end

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
