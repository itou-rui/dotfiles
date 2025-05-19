local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local get_filetype = require("plugins.copilotchat.utils.get_filetype")
local new_vertical_window = require("plugins.copilotchat.utils.open_window").new_vertical_window

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
	local sticky = {
		"/SystemPromptFixBugs",
		"#reply_language:" .. language,
		"#register:0",
	}

	require("fzf-lua").files({
		prompt = "Related Files> ",
		actions = {
			["default"] = function(selected_files)
				selected_files = selected_files or {}
				local file_tags = vim.tbl_map(function(f)
					local clean = f:gsub("^%s*", ""):gsub("^[^%w%./\\-_]+ *", "")
					return "#file:" .. clean
				end, selected_files)
				vim.list_extend(sticky, file_tags)

				new_vertical_window(prompt, {
					system_prompt = system_prompt.build({
						role = "debugger",
						character = "ai",
						guideline = { change_code = true, localization = true },
						specialties = get_filetype(selection and selection.filetype or nil),
						format = "fix_code_bugs",
					}),
					sticky = sticky,
				})
			end,
		},
		multi = true,
	})
end

return fix_code_bugs
