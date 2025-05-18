local prompts_module = require("plugins.copilotchat.prompts")
local language = prompts_module.language
local build_system_prompt = require("plugins.copilotchat.utils.build_system_prompt")
local get_filetype = require("plugins.copilotchat.utils.get_filetype")
local new_float_window = require("plugins.copilotchat.utils.open_window").new_float_window

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

				new_float_window("Write an explanation for the selected code as paragraphs of text.", {
					system_prompt = build_system_prompt({
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
