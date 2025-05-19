return {

	-- Toggle window
	{ "<leader>aa", "", desc = "Toggle window", mode = { "n", "v" } },
	{
		"<leader>aav",
		require("plugins.copilotchat.utils.window").toggle_vertical,
		desc = "Vertical",
		mode = { "n", "v" },
	},
	{
		"<leader>aaf",
		require("plugins.copilotchat.utils.window").toggle_float,
		desc = "Float",
		mode = { "n", "v" },
	},

	-- Clear
	{
		"<leader>ax",
		require("plugins.copilotchat.utils.window").clear,
		desc = "Clear",
		mode = { "n", "v" },
	},

	-- List chat history
	{
		"<leader>ah",
		require("plugins.copilotchat.utils.chat_history").list,
		desc = "List chat history",
		mode = { "n", "v" },
	},

	--  Perplexity Search
	{
		"<leader>as",
		require("plugins.copilotchat.chats.search"),
		desc = "Perplexity Search",
		mode = { "n", "v" },
	},

	-- Code
	{ "<leader>ac", "", desc = "Code actions", mode = { "n", "v" } },
	{
		"<leader>aca",
		require("plugins.copilotchat.actions.code.analyze"),
		desc = "Analyze",
		mode = { "n", "v" },
	},
	{ "<leader>acf", "", desc = "Fixs", mode = { "n", "v" } },
	{
		"<leader>acfb",
		require("plugins.copilotchat.actions.fix_code_bugs"),
		desc = "Bugs",
		mode = { "n", "v" },
	},
	{
		"<leader>ace",
		require("plugins.copilotchat.actions.explain_code"),
		desc = "Explain",
		mode = { "n", "v" },
	},
	{
		"<leader>acr",
		require("plugins.copilotchat.actions.review_code"),
		desc = "Review",
		mode = { "n", "v" },
	},
	{
		"<leader>acd",
		require("plugins.copilotchat.actions.code.doc"),
		desc = "Doc",
		mode = { "n", "v" },
	},

	-- Chat
	{
		"<leader>aC",
		require("plugins.copilotchat.actions.chat").open,
		desc = "Open chat",
		mode = { "n", "v" },
	},

	-- Git
	{ "<leader>ag", "", desc = "Git", mode = { "n", "v" } },
	{
		"<leader>agc",
		require("plugins.copilotchat.actions.commit").execute,
		desc = "Commit",
		mode = { "n", "v" },
	},
	{
		"<leader>agp",
		require("plugins.copilotchat.actions.git.pullrequest"),
		desc = "Pull Request",
		mode = { "n", "v" },
	},

	-- Utils
	{ "<leader>au", "", desc = "Utils", mode = { "n", "v" } },
	{
		"<leader>aus",
		require("plugins.copilotchat.actions.utils.spelling"),
		desc = "Spelling",
		mode = { "n", "v" },
	},
	{
		"<leader>aut",
		require("plugins.copilotchat.actions.utils.translate").translation_vertical,
		desc = "Translate",
		mode = { "n", "v" },
	},
	{
		"<leader>auo",
		require("plugins.copilotchat.actions.utils.output_template"),
		desc = "Output template",
		mode = { "n", "v" },
	},
}
