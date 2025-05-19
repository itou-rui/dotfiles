local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")

local function doc_code()
	vim.ui.select(system_languages.list, {
		prompt = "Select content language> ",
	}, function(selected_language)
		if not selected_language or selected_language == "" then
			selected_language = system_languages.default
		end

		local sticky = {
			"/SystemPromptCodeDoc",
			"#content_language:" .. selected_language,
		}

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

					window.open_vertical('Generate documentation comments for the "selected content".', {
						sticky = sticky,
					})
				end,
			},
			multi = true,
		})
	end)
end

return doc_code
