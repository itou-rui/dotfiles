local system_languages = require("plugins.copilotchat.utils.system_languages")
local window = require("plugins.copilotchat.utils.window")

local function pullrequest()
	vim.ui.select({ "main", "develop" }, { prompt = "Select base branch> " }, function(selected_branch)
		if not selected_branch or selected_branch == "" then
			return
		end

		vim.ui.select(system_languages.list, { prompt = "Select content language> " }, function(selected_language)
			if not selected_language or selected_language == "" then
				selected_language = system_languages.default
			end

			window.open_float("Create the contents of a 'Pull Request' based on the contents of the given Diff.", {
				sticky = {
					"/SystemPromptGenerate",
					"#content_language:" .. selected_language,
					"#system:`git diff " .. selected_branch .. "`",
					"#file:.github/PULL_REQUEST_TEMPLATE.md",
					"#file:.github/pull_request_template.md",
				},
				selection = false,
			})
		end)
	end)
end

return pullrequest
