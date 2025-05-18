local FILETYPE_CONFIGS = {
	angular = {
		patterns = {
			"%.component%.ts$",
			"%.component%.html$",
			"%.module%.ts$",
		},
		filetypes = { "htmlangular" },
		prompts = { "angular", "javascript", "typescript" },
	},
	ansible = {
		filetypes = { "yaml" },
		prompts = { "ansible" },
	},
	css = {
		filetypes = { "css", "scss", "less" },
		prompts = { "css" },
		patterns = {
			"%.css$",
			"%.scss$",
			"%.module%.css$",
		},
	},
	dockerfile = {
		filetypes = { "dockerfile" },
		prompts = { "docker" },
	},
	javascript = {
		filetypes = { "javascript" },
		prompts = { "javascript" },
	},
	python = {
		filetypes = { "python" },
		prompts = { "python" },
	},
	typescript = {
		filetypes = { "typescript" },
		prompts = { "javascript", "typescript" },
	},
	neovim = {
		filetypes = { "vim", "lua" },
		prompts = { "neovim", "lua" },
		contexts = { "url:https://github.com/ruicsh/nvim-config" },
	},
	rust = {
		filetypes = { "rust" },
		prompts = { "rust" },
	},
	react = {
		filetypes = { "typescriptreact" },
		prompts = { "react", "javascript", "typescript" },
	},
	zsh = {
		filetypes = { "zsh" },
		prompts = { "zsh" },
	},
}

-- Precompute filetype to config mapping for fast lookup
local filetype_to_config = {}
for _, config in pairs(FILETYPE_CONFIGS) do
	if config.filetypes then
		for _, ft in ipairs(config.filetypes) do
			filetype_to_config[ft] = config
		end
	end
end

---@param filetype string | ("ts" | "js" | "python" | "rust" | "docker" | "react" | "neovim" | "lua" | "zsh" | "ansible" | "css" | "htmlangular")
local function get_filetype(filetype)
	filetype = filetype or vim.bo.filetype
	local filename = vim.fn.expand("%:t")

	-- Fast path: direct filetype match
	if filetype_to_config[filetype] then
		return filetype_to_config[filetype].prompts
	end

	-- Slow path: pattern match
	for _, config in pairs(FILETYPE_CONFIGS) do
		if config.patterns then
			for _, pattern in ipairs(config.patterns) do
				if filename:match(pattern) then
					return config.prompts
				end
			end
		end
	end
end

return get_filetype
