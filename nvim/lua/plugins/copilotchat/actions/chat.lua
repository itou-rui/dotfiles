M = {}

local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local function generate_system_prompt(role, character, specialty)
	if not role or not character or not specialty then
		return nil
	end

	-- Uppercase the first letter of each component
	local function capitalize(str)
		return (str:gsub("^%l", string.upper))
	end

	-- If character is "ai", format as "LuaAssistant"
	if character == "ai" then
		return capitalize(specialty) .. capitalize(role)
	end

	-- Otherwise, format as "FriendlyPythonTeacher" style
	return capitalize(character) .. capitalize(specialty) .. capitalize(role)
end

local function open_chat_window(role, character, specialty, selection, style)
	local fallback_selection = function(source)
		local select = require("CopilotChat.select")
		return select.visual(source) or select.buffer(source)
	end

	local stickies = sticky.build({
		system_prompt = generate_system_prompt(role, character, specialty),
		filenames = selection and selection.filenames or nil,
		reply_language = system_languages.default,
	})

	vim.ui.input({ prompt = "Prompt> " }, function(input)
		if not input or input == "" then
			input = ""
		end

		if style == "vertical" then
			window.open_vertical(input, {
				sticky = stickies,
				callback = fallback_selection,
			})
		else
			window.open_float(input, {
				sticky = stickies,
				callback = fallback_selection,
			})
		end
	end)
end

local function select_style(role, character, specialty, selection)
	vim.ui.select({ "float", "vertical" }, {
		prompt = "Select window style> ",
	}, function(style)
		open_chat_window(role, character, specialty, selection, style)
	end)
end

local function on_specialty_selected(role, character, selection, specialty)
	if not specialty or specialty == "" then
		specialty = nil
	end
	select_style(role, character, specialty, selection)
end

local function select_specialty(role, character, selection)
	vim.ui.select(system_prompt.specialties, {
		prompt = "Select specialty> ",
	}, function(specialty)
		on_specialty_selected(role, character, selection, specialty)
	end)
end

local function on_character_selected(role, selection, character)
	if not character or character == "" then
		character = "friendly"
	end
	select_specialty(role, character, selection)
end

local function select_character(role, selection)
	vim.ui.select(system_prompt.characters, {
		prompt = "Select character> ",
	}, function(character)
		on_character_selected(role, selection, character)
	end)
end

local function on_role_selected(role, selection)
	if not role or role == "" then
		role = "assistant"
	end

	if role == "assistant" then
		select_specialty(role, "ai", selection)
	elseif role == "teacher" then
		select_character(role, selection)
	end
end

M.open = function()
	local selection = require("CopilotChat").get_selection()

	vim.ui.select(system_prompt.roles, {
		prompt = "Select role> ",
	}, function(role)
		on_role_selected(role, selection)
	end)
end

return M
