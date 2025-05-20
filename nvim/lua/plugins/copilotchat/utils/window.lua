local copilotchat = require("CopilotChat")

local M = {}

M.float_window = {
	layout = "float",
	relative = "cursor",
	width = 1,
	height = 0.8,
	row = 1,
}

M.reset_title = function()
	vim.g.copilot_chat_title = nil
end

M.reset_chat = function()
	copilotchat.reset()
end

M.clear = function()
	M.reset_title()
	M.reset_chat()
end

---@param prompt string | nil
---@param opts CopilotChat.config
M.open = function(prompt, opts)
	M.clear()
	if prompt and prompt ~= "" then
		copilotchat.ask(prompt, opts)
	else
		copilotchat.open(opts)
	end
end

---@param prompt string
---@param opts CopilotChat.config
M.open_float = function(prompt, opts)
	opts = opts or {}
	opts.window = M.float_window
	M.open(prompt, opts)
end

---@param prompt string
---@param opts CopilotChat.config
M.open_vertical = function(prompt, opts)
	opts = opts or {}
	opts.window = { layout = "vertical" }
	M.open(prompt, opts)
end

---@param opts CopilotChat.config
M.toggle = function(opts)
	copilotchat.open(opts)
end

---@param opts CopilotChat.config
M.toggle_float = function(opts)
	opts = opts or {}
	opts.window = M.float_window
	M.toggle(opts)
end

---@param opts CopilotChat.config
M.toggle_vertical = function(opts)
	opts = opts or {}
	opts.window = { layout = "vertical" }
	M.toggle(opts)
end

return M
