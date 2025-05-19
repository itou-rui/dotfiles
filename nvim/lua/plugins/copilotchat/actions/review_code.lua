local copilot_chat_ns = vim.api.nvim_create_namespace("copilot-chat-diagnostics")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local get_filetype = require("plugins.copilotchat.utils.get_filetype")
local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local window = require("plugins.copilotchat.utils.window")

local function review_code()
	local selection = require("CopilotChat").get_selection()

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

	window.open_vertical(prompt, {
		system_prompt = system_prompt.build({
			role = "assistant",
			character = "ai",
			guideline = { localization = true },
			specialties = get_filetype(selection and selection.filetype or nil),
			question_focus = "selection",
			format = "review",
		}),
		sticky = { "#reply_language:" .. language },
		callback = function(response, source)
			local diagnostics = {}
			for line in response:gmatch("[^\r\n]+") do
				if line:find("^line=") then
					local start_line = nil
					local end_line = nil
					local message = nil
					local single_match, message_match = line:match("^line=(%d+): (.*)$")
					if not single_match then
						local start_match, end_match, m_message_match = line:match("^line=(%d+)-(%d+): (.*)$")
						if start_match and end_match then
							start_line = tonumber(start_match)
							end_line = tonumber(end_match)
							message = m_message_match
						end
					else
						start_line = tonumber(single_match)
						end_line = start_line
						message = message_match
					end

					if start_line and end_line then
						table.insert(diagnostics, {
							lnum = start_line - 1,
							end_lnum = end_line - 1,
							col = 0,
							message = message,
							severity = vim.diagnostic.severity.WARN,
							source = "Copilot Review",
						})
					end
				end
			end
			vim.diagnostic.set(copilot_chat_ns, source.bufnr, diagnostics)
			return response
		end,
	})
end

return review_code
