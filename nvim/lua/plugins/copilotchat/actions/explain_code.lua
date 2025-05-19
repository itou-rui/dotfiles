local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local get_filetype = require("plugins.copilotchat.utils.get_filetype")
local window = require("plugins.copilotchat.utils.window")

local function explain_code()
	local selection = require("CopilotChat").get_selection()
	local sticky = { "#reply_language:" .. language }

	require("fzf-lua").files({
		prompt = "Files> ",
		actions = {
			["default"] = function(selected_files)
				selected_files = selected_files or {}
				local file_tags = vim.tbl_map(function(f)
					local clean = f:gsub("^%s*", ""):gsub("^[^%w%./\\-_]+ *", "")
					return "#file:" .. clean
				end, selected_files)
				vim.list_extend(sticky, file_tags)

				window.open("Write an explanation for the selected code as paragraphs of text.", {
					system_prompt = system_prompt.build({
						role = "teacher",
						character = "ai",
						guideline = { localization = true },
						specialties = get_filetype(selection and selection.filetype or nil),
						question_focus = "selection",
						format = "explain",
					}),
					sticky = sticky,
					selection = function(source)
						local select = require("CopilotChat.select")
						return select.visual(source) or select.buffer(source)
					end,
				})
			end,
		},
		multi = true,
	})
end

return explain_code
