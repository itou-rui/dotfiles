local window = require("plugins.copilotchat.utils.window")

local function spelling()
	window.open_vertical("Check the spelling of the characters contained in the selected range.", {
		sticky = {
			"/SystemPromptSpelling",
		},
	})
end

return spelling
