local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local prompt = [[
Fix the bug based on the given stack trace (`vim_register_0`).

**Note**:

- "Location of Occurrence" refers to where the error was thrown.
- "Root Cause" refers to the underlying cause that triggered the error.
  - If the cause is unclear, make a judgment based on the principles of "Best Practices."
  - If you followed specific rules or references, list the source (MDN, official TypeScript, etc.) in Source.
- Visually represent the bug occurrence flow using ASCII art.
- If there are multiple fixes, separate each into its own code block.
  ]]

local function fix_code_bugs()
	local selection = require("CopilotChat").get_selection()
	require("fzf-lua").files({
		prompt = "Related Files> ",
		actions = {
			["default"] = function(selected_files)
				window.open_vertical(prompt, {
					system_prompt = system_prompt.build({
						role = "debugger",
						character = "ai",
						guideline = { change_code = true, localization = true },
						specialty = selection and selection.filetype or nil,
						format = "fix_code_bugs",
					}),
					sticky = sticky.build({
						reply_language = system_languages.default,
						file = sticky.build_file_contexts(selected_files),
						register = "system_clipboard",
					}),
				})
			end,
		},
		multi = true,
	})
end

return fix_code_bugs
