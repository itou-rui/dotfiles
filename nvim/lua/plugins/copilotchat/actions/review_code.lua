local copilot_chat_ns = vim.api.nvim_create_namespace("copilot-chat-diagnostics")
local diagnostics_parser = require("plugins.copilotchat.utils.diagnostics")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local prompt = [[
Review the "selected code".

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

If no issues are found, confirm the code is well-written and explain why.
  ]]

local function review_code()
	local selection = require("CopilotChat").get_selection()

	window.open_vertical(prompt, {
		system_prompt = system_prompt.build({
			role = "assistant",
			character = "ai",
			guideline = { localization = true },
			specialty = selection and selection.filetype or nil,
			question_focus = "selection",
			format = "review",
		}),
		sticky = sticky.build({
			reply_language = system_languages.default,
		}),
		selection = function(source)
			local select = require("CopilotChat.select")
			return select.visual(source) or select.buffer(source)
		end,
		callback = function(response, source)
			chat_history.save(response, {
				used_prompt = prompt,
				tag = "Review",
			})
			local diagnostics = diagnostics_parser.parse_review_response("Copilot Review", response)
			vim.diagnostic.set(copilot_chat_ns, source.bufnr, diagnostics)
			return response
		end,
	})
end

return review_code
