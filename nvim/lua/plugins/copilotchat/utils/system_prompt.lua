---@alias Role
---| "assistant"
---| "teacher"
---| "reviewer"
---| "architect"
---| "debugger"
---| "DevOps"
---| "performer"
---| "tester"
---| "security"
---| "commiter"
---| "documenter"

---@alias Character
---| "ai"
---| "friendly"
---| "cute"
---| "tsundere"

---@alias Specialty string|FiletypeConfigPrompt

---@class Guideline
---@field change_code boolean|nil
---@field localization boolean|nil
---@field software_principles boolean|nil

---@alias QuestionFocus "selection"

---@alias Format "explain"|"review"|"fix_bug"|"commit"|"developer_document"|"analyze_variable"|"analyze_function"

---@class BuildOptions
---@field role Role|nil
---@field character Character|nil
---@field specialties Specialty|false|table<Specialty>|nil
---@field guideline Guideline|nil
---@field question_focus QuestionFocus|nil
---@field format Format|nil

local filetype = require("plugins.copilotchat.utils.filetype")

local M = {}

local function load_prompt(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return ""
	end
	local content = file:read("*a")
	file:close()
	return content
end

---@type Role[]
M.roles = {
	"assistant",
	"teacher",
	"reviewer",
	"architect",
	"debugger",
	"DevOps",
	"performer",
	"tester",
	"security",
	"commiter",
	"documenter",
}

---@type Character[]
M.characters = {
	"ai",
	"friendly",
	"cute",
	"tsundere",
}

---@return Specialty[]
M.specialties = (function()
	local specialties_set = {}
	for _, config in pairs(filetype.FILETYPE_CONFIGS) do
		if config.prompts then
			for _, prompt in ipairs(config.prompts) do
				specialties_set[prompt] = true
			end
		end
	end
	local specialties = {}
	for specialty, _ in pairs(specialties_set) do
		table.insert(specialties, specialty)
	end
	table.sort(specialties)
	return specialties
end)()

--- Converts the given role, character, and optional specialty into a "sticky" identifier string.
--- The function capitalizes each component and concatenates them in the order: character, specialty (if provided), and role.
---
--- This is typically used to generate a unique, human-readable identifier for a system prompt persona or configuration.
---
--- Example:
---   to_sticky("assistant", "ai", "python") --> "AIPythonAssistant"
---   to_sticky("user", "developer")         --> "DeveloperUser"
---
--- @param role Role                -- The role of the entity (e.g., "assistant", "user").
--- @param character Character      -- The character or persona name (e.g., "ai").
--- @param specialty Specialty|nil  -- An optional specialty or sub-role (e.g., "python").
--- @return string                  -- The concatenated, capitalized identifier string, or nil if inputs are invalid.
M.to_sticky = function(role, character, specialty)
	---@param str string
	local function capitalize(str)
		return str == "ai" and "AI" or (str:gsub("^%l", string.upper))
	end

	local r = capitalize(role)
	local c = capitalize(character)
	if specialty and specialty ~= "" then
		local s = capitalize(specialty)
		return s .. c .. r
	else
		return c .. r
	end
end

---@param opts BuildOptions
---@return string
M.build = function(opts)
	-- Helper to build prompt path
	local config_path = vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/"
	local function prompt_path(subpath)
		return config_path .. subpath
	end

	local prompt_parts = {}

	-- Role
	local role = opts.role or "assistant"
	table.insert(prompt_parts, load_prompt(prompt_path("roles/" .. role .. ".md")))
	table.insert(prompt_parts, load_prompt(prompt_path("guidelines/base.md")))

	-- Character
	local character = opts.character or "ai"
	table.insert(prompt_parts, load_prompt(prompt_path("characters/" .. character .. ".md")))

	-- Specialties
	table.insert(prompt_parts, load_prompt(prompt_path("specialties/base.md")))
	local specialties = filetype.add_related(opts.specialties)
	if specialties and #specialties > 0 then
		local failed_languages = {}
		for _, specialty in ipairs(specialties) do
			local specialty_prompt = load_prompt(prompt_path("specialties/" .. specialty .. ".md"))
			if specialty_prompt ~= "" then
				table.insert(prompt_parts, specialty_prompt)
			else
				table.insert(failed_languages, specialty)
			end
		end

		if #failed_languages > 0 then
			vim.notify("Failed to load specialty: " .. table.concat(failed_languages, ", "), vim.log.levels.WARN)
		end
	end

	-- Guideline
	if opts.guideline then
		if opts.guideline.change_code then
			table.insert(prompt_parts, load_prompt(prompt_path("guidelines/change_code.md")))
		end
		if opts.guideline.localization then
			table.insert(prompt_parts, load_prompt(prompt_path("guidelines/localization.md")))
		end
		if opts.guideline.software_principles then
			table.insert(prompt_parts, load_prompt(prompt_path("guidelines/software_principles.md")))
		end
	end

	-- Question Focus
	if opts.question_focus then
		table.insert(prompt_parts, load_prompt(prompt_path("question_focus/" .. opts.question_focus .. ".md")))
	end

	-- Format
	if opts.format then
		table.insert(prompt_parts, load_prompt(prompt_path("formats/" .. "base.md")))
		table.insert(prompt_parts, load_prompt(prompt_path("formats/" .. opts.format .. ".md")))
	end

	return table.concat(prompt_parts, "\n")
end

return M
