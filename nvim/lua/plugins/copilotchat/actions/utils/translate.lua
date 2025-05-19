local prompts_module = require("plugins.copilotchat.prompts")
local languages = prompts_module.languages
local window = require("plugins.copilotchat.utils.window")

---@param style "vertical" | "float"
local function translation(style)
	vim.ui.select(languages, {
		prompt = "Select Language> ",
	}, function(selected_language)
		if not selected_language or selected_language == "" then
			return
		end

		local prompt = "Translate the contents of the given Selection with `Content_Language`."
		local sticky = {
			"/SystemPromptTranslate",
			"#content_language:" .. selected_language,
		}

		if style == "vertical" then
			window.open_vertical(prompt, {
				sticky = sticky,
			})
		elseif style == "float" then
			window.open_vertical(prompt, {
				sticky = sticky,
			})
		end
	end)
end

local function translation_vertical()
	translation("vertical")
end

local function translation_float()
	translation("float")
end

return {
	translation = translation,
	translation_vertical = translation_vertical,
	translation_float = translation_float,
}
