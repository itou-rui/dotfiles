local function load_prompt(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

-- MacOS Only
local system_languages_raw = vim.fn.system("defaults read -g AppleLanguages")
local system_languages = vim.split(system_languages_raw:gsub("[%(%)]", ""):gsub('"', ""):gsub("%s+", ""), ",")
local system_language = system_languages_raw:match('"(.-)"') or "english"

return {

	-- CopilotC-Nvim/CopilotChat.nvim

	{
		"CopilotC-Nvim/CopilotChat.nvim",

		-- debug = true,
		-- log_level = "debug",
		show_help = "yes",
		highlight_headers = false,
		separator = "---",
		error_header = "> [!ERROR] Error",

		dependencies = {
			{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
			{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
		},
		build = "make tiktoken", -- Only on MacOS or Linux

		opts = function(_, options)
			-- providers
			options.providers = {
				ollama = {
					prepare_input = require("CopilotChat.config.providers").copilot.prepare_input,
					prepare_output = require("CopilotChat.config.providers").copilot.prepare_output,

					get_models = function(headers)
						local response, err =
							require("CopilotChat.utils").curl_get("http://localhost:11434/v1/models", {
								headers = headers,
								json_response = true,
							})

						if err then
							error(err)
						end

						return vim.tbl_map(function(model)
							return {
								id = model.id,
								name = model.id,
							}
						end, response.body.data)
					end,

					embed = function(inputs, headers)
						local response, err =
							require("CopilotChat.utils").curl_post("http://localhost:11434/v1/embeddings", {
								headers = headers,
								json_request = true,
								json_response = true,
								body = {
									input = inputs,
									model = "all-minilm",
								},
							})

						if err then
							error(err)
						end

						return response.body.data
					end,

					get_url = function()
						return "http://localhost:11434/v1/chat/completions"
					end,
				},
			}

			options.prompts = {
				-- System prompts
				SystemPromptInstructions = {
					system_prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_instructions.md"
					),
				},
				SystemPromptReview = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_review.md"),
				},
				SystemPromptExplain = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_explain.md"),
				},

				-- /Explain
				Explain = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain.md"),
					sticky = { "/SystemPromptExplain", "#language:" .. system_language },
					description = "Used to understand what the specified code is doing.",
				},

				-- /Review
				Review = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review.md"),
					sticky = { "/SystemPromptReview", "#language:" .. system_language },
					description = "Used to perform a review for a given code.",
					callback = function(response, source)
						local diagnostics = {}
						for line in response:gmatch("[^\r\n]+") do
							if line:find("^line=") then
								local start_line = nil
								local end_line = nil
								local message = nil
								local single_match, message_match = line:match("^line=(%d+): (.*)$")
								if not single_match then
									local start_match, end_match, m_message_match =
										line:match("^line=(%d+)-(%d+): (.*)$")
									if start_match and end_match then
										start_line = tonumber(start_match)
										end_line = tonumber(end_match)
										message = m_message_match
									end
								else
									start_line = tonumber(single_match)
									end_line = start_line
									message = message_match
								end

								if start_line and end_line then
									table.insert(diagnostics, {
										lnum = start_line - 1,
										end_lnum = end_line - 1,
										col = 0,
										message = message,
										severity = vim.diagnostic.severity.WARN,
										source = "Copilot Review",
									})
								end
							end
						end
						vim.diagnostic.set(
							vim.api.nvim_create_namespace("copilot-chat-diagnostics"),
							source.bufnr,
							diagnostics
						)
						return response
					end,
				},

				-- /Fix
				Fix = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "It is used to fix problems (bugs and errors) occurring in the code.",
				},

				-- /Optimize
				Optimize = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/optimize.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "It is used to propose optimizations for improving the performance and readability of the code.",
				},

				-- /Docs
				Docs = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Used to generate detailed documentation for the provided code, including descriptions for functions, classes, arguments, and usage examples.",
				},

				-- /Tests
				Tests = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/test.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Used to create test cases for the provided code, covering critical paths, edge cases, and various test types.",
				},

				-- /FixDiagnostic
				FixDiagnostic = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix_diagnostic.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Used to fix issues in the code based on diagnostic tool results, providing specific fixes and explanations.",
				},

				-- Commit
				Commit = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit.md"),
					sticky = {
						"/SystemPromptInstructions",
						"#language:" .. system_language,
						"#git:staged",
						"#file:./commitlint.config.js",
						"#file:./.cz-config.js",
					},
					description = "Used to create commit messages based on staged changes.",
				},

				-- CommitMerge
				CommitPR = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request.md"),
					sticky = {
						"/SystemPromptInstructions",
						"#language:" .. system_language,
						"#file:./commitlint.config.js",
						"#file:./.cz-config.js",
					},
					description = "Create a commit message based on the content of the PullRequest.",
				},

				-- Evaluation
				Evaluation = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation.md"),
					sticky = { "/SystemPromptExplain", "#language:" .. system_language },
					description = "Used to evaluate the quality, performance, and maintainability of the specified code, along with recommendations for improvement.",
				},

				-- Generate Pull Request
				GeneratePullRequest = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request.md"),
					sticky = {
						"/SystemPromptInstructions",
						"#language:" .. system_language,
						"#file:.github/PULL_REQUEST_TEMPLATE.md",
						"#file:.github/pull_request_template.md",
						"#system:`git diff main`",
					},
					description = "Generate pull request content.",
				},

				Summarize = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/summarize.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Summarizes a given sentence.",
				},

				Spelling = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/spelling.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Corrects grammatical and spelling errors in assigned sentences.",
				},

				Wording = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/wording.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Improve grammar and expression of assigned sentences.",
				},

				Concise = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/concise.md"),
					sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
					description = "Rewrite the specified sentences in a more concise manner.",
				},
			}

			-- contexts
			options.contexts = {
				file = {
					input = function(callback)
						local fzf = require("fzf-lua")
						local fzf_path = require("fzf-lua.path")
						fzf.files({
							complete = function(selected, opts)
								local file = fzf_path.entry_to_file(selected[1], opts, opts._uri)
								if file.path == "none" then
									return
								end
								vim.defer_fn(function()
									callback(file.path)
								end, 100)
							end,
						})
					end,
				},

				language = {
					description = "Specifies the language in which AL responds.",
					input = function(callback)
						vim.ui.select(system_languages, {
							prompt = "Select language> ",
						}, callback)
					end,
					resolve = function(input)
						return {
							{
								content = input or "japanese",
								filename = "Response_Language",
								filetype = "text",
							},
						}
					end,
				},
			}

			-- Window layout settings
			options.window = {
				layout = function()
					-- vim.notify("options.window.layout: Start debug", vim.log.levels.DEBUG)

					-- For screen sizes of 16 inches or smaller
					if vim.o.lines <= 45 then
						return "horizontal"
					end

					-- Check the current window split status
					local wins = vim.api.nvim_list_wins()

					-- Filter only valid windows
					local valid_wins = vim.tbl_filter(function(win)
						return vim.api.nvim_win_is_valid(win)
					end, wins)

					if #valid_wins > 2 then
						-- Check the positioning of the first two valid windows
						local win1_pos = vim.api.nvim_win_get_position(valid_wins[1])
						local win2_pos = vim.api.nvim_win_get_position(valid_wins[2])

						-- If col (X coordinate) is the same, horizontally split (divided into top and bottom)
						if win1_pos[2] == win2_pos[2] then
							return "vertical"
						end

						-- Vertical division if col (X coordinate) is different (divided into left and right)
						return "horizontal"
					end

					-- Default is vertical (if not split)
					return "vertical"
				end,
			}
		end,
	},

	--  Perplexity Search
	vim.keymap.set({ "n", "v" }, "<leader>acs", function()
		local input = vim.fn.input("Perplexity: ")
		if input ~= "" then
			require("CopilotChat").ask(input, {
				agent = "perplexityai",
				sticky = { "/SystemPromptInstructions", "#language:" .. system_language },
				selection = false,
			})
		end
	end, { desc = "CopilotChat - Search" }),
}
