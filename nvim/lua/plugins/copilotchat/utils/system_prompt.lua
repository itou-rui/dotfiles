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

---@alias QuestionFocus "selection"

---@alias Format "explain" | "review" | "fix_bug" | "commit" | "developer_document"

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
