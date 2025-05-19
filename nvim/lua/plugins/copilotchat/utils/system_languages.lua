local M = {}

local raw_list = vim.fn.system("defaults read -g AppleLanguages")

M.raw = raw_list
M.list = vim.split(raw_list:gsub("[%(%)]", ""):gsub('"', ""):gsub("%s+", ""), ",")

---@type string
M.default = (raw_list:match('"(.-)"')):match("(%a+)$-")

return M
