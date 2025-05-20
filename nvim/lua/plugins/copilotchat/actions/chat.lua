local chat_select = require("CopilotChat.select")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local system_prompt = require("plugins.copilotchat.utils.system_prompt")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local window = require("plugins.copilotchat.utils.window")
local sticky = require("plugins.copilotchat.utils.sticky")
local selection = require("plugins.copilotchat.utils.selection")

local M = {}

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

local function open_chat_window(role, character, specialty, style)
	local fallback_selection = function(source)
		return chat_select.visual(source) or chat_select.buffer(source)
	end

	local stickies = sticky.build({
		system_prompt = generate_system_prompt(role, character, specialty),
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

local function select_style(role, character, specialty)
	vim.ui.select({ "float", "vertical" }, {
		prompt = "Select window style> ",
	}, function(style)
		selection.restore(function()
			open_chat_window(role, character, specialty, style)
		end)
	end)
end

local function on_specialty_selected(role, character, specialty)
	if not specialty or specialty == "" then
		specialty = nil
	end
	select_style(role, character, specialty)
end

local function select_specialty(role, character)
	vim.ui.select(system_prompt.specialties, {
		prompt = "Select specialty> ",
	}, function(specialty)
		on_specialty_selected(role, character, specialty)
	end)
end

local function on_character_selected(role, character)
	if not character or character == "" then
		character = "friendly"
	end
	select_specialty(role, character)
end

local function select_character(role)
	vim.ui.select(system_prompt.characters, {
		prompt = "Select character> ",
	}, function(character)
		on_character_selected(role, character)
	end)
end

local function on_role_selected(role)
	if not role or role == "" then
		role = "assistant"
	end

	if role == "assistant" then
		select_specialty(role, "ai")
	elseif role == "teacher" then
		select_character(role)
	end
end

M.open = function()
	vim.ui.select(system_prompt.roles, {
		prompt = "Select role> ",
	}, function(role)
		on_role_selected(role)
	end)
end

return M
