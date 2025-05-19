local M = {}

local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")

local function generate_system_prompt(role, character, specialty)
	if not role or not character then
		return nil
	end

	local function capitalize(str)
		return (str:gsub("^%l", string.upper))
	end

	if character == "ai" then
		return capitalize(specialty or "") .. capitalize(role)
	end

	local parts = { capitalize(character) }
	if specialty and specialty ~= "" then
		table.insert(parts, capitalize(specialty))
	end
	table.insert(parts, capitalize(role))
	return table.concat(parts)
end

local function fallback_chat_title(role, character, specialty)
	-- Capitalize helper (same as in generate_system_prompt)
	local function capitalize(str)
		return (str and str ~= "") and (str:gsub("^%l", string.upper)) or ""
	end

	-- Handle "ai" character/role context
	if character == "ai" or role == "ai" then
		return "New chat with AI about " .. (specialty and capitalize(specialty) or "General")
	end

	-- Compose title with available context
	local parts = {}
	if character and character ~= "" then
		table.insert(parts, capitalize(character))
	end
	if role and role ~= "" then
		table.insert(parts, capitalize(role))
	end
	if specialty and specialty ~= "" then
		table.insert(parts, capitalize(specialty))
	end

	if #parts > 0 then
		return "New chat about " .. table.concat(parts, " ")
	else
		return "New chat"
	end
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

		local callback = function(response)
			chat_history.save(response, {
				used_prompt = input or fallback_chat_title(role, character, specialty),
				tag = "Instruction",
			})
			return response
		end

		if style == "vertical" then
			window.open_vertical(input, {
				sticky = stickies,
				selection = fallback_selection,
				callback = callback,
			})
		else
			window.open_float(input, {
				sticky = stickies,
				selection = fallback_selection,
				callback = callback,
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
