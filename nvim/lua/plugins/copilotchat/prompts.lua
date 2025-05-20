local M = {}

local system_prompt = require("plugins.copilotchat.utils.system_prompt")

local function build_assistant(specialty)
	return system_prompt.build({
		role = "assistant",
		character = "ai",
		guideline = { change_code = true, localization = true },
		question_focus = "selection",
		specialties = specialty,
	})
end

local function build_teacher(character, specialty)
	return system_prompt.build({
		role = "teacher",
		character = character,
		guideline = { localization = true },
		specialties = specialty,
	})
end

local build_documenter = function(specialty)
	return system_prompt.build({
		role = "documenter",
		character = "ai",
		guideline = { change_code = true, localization = true },
		specialties = specialty,
	})
end

M.prompts = {
	-- Assistants
	Assistant = {
		system_prompt = build_assistant(""),
	},
	LuaAssistant = {
		system_prompt = build_assistant("lua"),
	},
	TypescriptAssistant = {
		system_prompt = build_assistant("typescript"),
	},
	JavascriptAssistant = {
		system_prompt = build_assistant("javascript"),
	},
	PythonAssistant = {
		system_prompt = build_assistant("python"),
	},
	DockerAssistant = {
		system_prompt = build_assistant("docker"),
	},
	ReactAssistant = {
		system_prompt = build_assistant("react"),
	},
	ZshAssistant = {
		system_prompt = build_assistant("zsh"),
	},
	CssAssistant = {
		system_prompt = build_assistant("css"),
	},

	-- Friendly Teacher
	FriendlyTeacher = {
		system_prompt = build_teacher("friendly", ""),
	},
	FriendlyLuaTeacher = {
		system_prompt = build_teacher("friendly", "lua"),
	},
	FriendlyTypescriptTeacher = {
		system_prompt = build_teacher("friendly", "typescript"),
	},
	FriendlyJavascriptTeacher = {
		system_prompt = build_teacher("friendly", "javascript"),
	},
	FriendlyPythonTeacher = {
		system_prompt = build_teacher("friendly", "python"),
	},
	FriendlyDockerTeacher = {
		system_prompt = build_teacher("friendly", "docker"),
	},
	FriendlyReactTeacher = {
		system_prompt = build_teacher("friendly", "react"),
	},
	FriendlyZshTeacher = {
		system_prompt = build_teacher("friendly", "zsh"),
	},
	FriendlyCssTeacher = {
		system_prompt = build_teacher("friendly", "css"),
	},

	-- Cute Teacher
	CuteTeacher = {
		system_prompt = build_teacher("cute", ""),
	},
	CuteLuaTeacher = {
		system_prompt = build_teacher("cute", "lua"),
	},
	CuteTypescriptTeacher = {
		system_prompt = build_teacher("cute", "typescript"),
	},
	CuteJavascriptTeacher = {
		system_prompt = build_teacher("cute", "javascript"),
	},
	CutePythonTeacher = {
		system_prompt = build_teacher("cute", "python"),
	},
	CuteDockerTeacher = {
		system_prompt = build_teacher("cute", "docker"),
	},
	CuteReactTeacher = {
		system_prompt = build_teacher("cute", "react"),
	},
	CuteZshTeacher = {
		system_prompt = build_teacher("cute", "zsh"),
	},
	CuteCssTeacher = {
		system_prompt = build_teacher("cute", "css"),
	},

	-- Tsundere Teacher
	TsundereTeacher = {
		system_prompt = build_teacher("tsundere", ""),
	},
	TsundereLuaTeacher = {
		system_prompt = build_teacher("tsundere", "lua"),
	},
	TsundereTypescriptTeacher = {
		system_prompt = build_teacher("tsundere", "typescript"),
	},
	TsundereJavascriptTeacher = {
		system_prompt = build_teacher("tsundere", "javascript"),
	},
	TsunderePythonTeacher = {
		system_prompt = build_teacher("tsundere", "python"),
	},
	TsundereDockerTeacher = {
		system_prompt = build_teacher("tsundere", "docker"),
	},
	TsundereReactTeacher = {
		system_prompt = build_teacher("tsundere", "react"),
	},
	TsundereZshTeacher = {
		system_prompt = build_teacher("tsundere", "zsh"),
	},
	TsundereCssTeacher = {
		system_prompt = build_teacher("tsundere", "css"),
	},

	-- Documenter
	Documenter = {
		system_prompt = build_documenter({ "markdown" }),
	},
	LuaDocumenter = {
		system_prompt = build_documenter({ "lua", "markdown" }),
	},
	TypescriptDocumenter = {
		system_prompt = build_documenter({ "typescript", "markdown" }),
	},
	JavascriptDocumenter = {
		system_prompt = build_documenter({ "javascript", "markdown" }),
	},
	PythonDocumenter = {
		system_prompt = build_documenter({ "python", "markdown" }),
	},
	DockerDocumenter = {
		system_prompt = build_documenter({ "docker", "markdown" }),
	},
	ReactDocumenter = {
		system_prompt = build_documenter({ "react", "markdown" }),
	},
	ZshDocumenter = {
		system_prompt = build_documenter({ "zsh", "markdown" }),
	},
	CssDocumenter = {
		system_prompt = build_documenter({ "css", "markdown" }),
	},
}

return M
