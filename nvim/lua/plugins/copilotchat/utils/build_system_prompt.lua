local function load_prompt(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return ""
	end
	local content = file:read("*a")
	file:close()
	return content
end

--- @class Guideline
--- @field change_code nil | boolean
--- @field localization nil | boolean

--- @class BuildOptions
--- @field role nil | "assistant" | "teacher" | "reviewer" | "architect" | "debugger" | "DevOps" | "performer" | "tester" | "security"
--- @field character nil | "ai" | "friendly" | "cute" | "tsundere"
--- @field specialties nil | ("ts" | "js" | "python" | "rust" | "docker" | "react" | "neovim" | "lua" | "zsh" | "ansible" | "css")[]
--- @field guideline nil | Guideline
--- @field question_focus nil | "selection"
--- @field format nil | "explain"

--- @param opts BuildOptions
local function build_system_prompt(opts)
	-- Role
	local role = opts.role or "assistant"
	local system_prompt = load_prompt(
		vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/roles/" .. role .. ".md"
	) .. "\n" .. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/guidelines/base.md")

	-- Character
	local character = opts.character or "ai"
	system_prompt = system_prompt
		.. "\n"
		.. load_prompt(
			vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/characters/" .. character .. ".md"
		)

	-- Specialties
	if opts.specialties then
		system_prompt = system_prompt
			.. "\n"
			.. load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/specialties/base.md")
		local failed_languages = {}
		for _, specialty in ipairs(opts.specialties) do
			local specialty_prompt = load_prompt(
				vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/specialties/" .. specialty .. ".md"
			)
			if specialty_prompt ~= "" then
				system_prompt = system_prompt .. "\n" .. specialty_prompt
			else
				table.insert(failed_languages, specialty)
			end
		end

		if failed_languages and #failed_languages > 0 then
			vim.notify("Failed to load specialty: " .. table.concat(failed_languages, ", "), vim.log.levels.WARN)
		end
	end

	-- Guideline
	if opts.guideline and opts.guideline.change_code then
		system_prompt = system_prompt
			.. "\n"
			.. load_prompt(
				vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/guidelines/change_code.md"
			)
	end
	if opts.guideline and opts.guideline.localization then
		system_prompt = system_prompt
			.. "\n"
			.. load_prompt(
				vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/guidelines/localization.md"
			)
	end

	-- Question Focus
	if opts.question_focus then
		system_prompt = system_prompt
			.. "\n"
			.. load_prompt(
				vim.fn.stdpath("config")
					.. "/lua/plugins/copilotchat/system_prompts/question_focus/"
					.. opts.question_focus
					.. ".md"
			)
	end

	-- Format
	if opts.format then
		system_prompt = system_prompt
			.. "\n"
			.. load_prompt(
				vim.fn.stdpath("config") .. "/lua/plugins/copilotchat/system_prompts/formats/" .. opts.format .. ".md"
			)
	end

	return system_prompt
end

return build_system_prompt
