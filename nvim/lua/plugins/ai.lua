return {

	-- CopilotC-Nvim/CopilotChat.nvim

	{
		"CopilotC-Nvim/CopilotChat.nvim",

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
			local select = require("CopilotChat.select")
			local cached_gitdiff = nil

			local function load_prompt(file_path)
				local file = io.open(file_path, "r")
				if not file then
					return nil
				end
				local content = file:read("*a")
				file:close()
				return content
			end

			-- providers
			options.providers = {
				ollama = {
					embeddings = "copilot_embeddings", -- Use Copilot as embedding provider

					resolve_context = function(context_type, content)
						-- vim.notify("Resolving context: " .. context_type, vim.log.levels.DEBUG)
						if context_type == "file" or context_type == "files" then
							return {
								role = "system",
								content = string.format("Context (%s): %s", context_type, content),
							}
						end
						return nil
					end,

					get_headers = function()
						-- vim.notify("Preparing Ollama request", vim.log.levels.DEBUG)
						return {
							["Content-Type"] = "application/json",
						}
					end,

					get_models = function(headers)
						local utils = require("CopilotChat.utils")
						local response = utils.curl_get("http://localhost:11434/api/tags", { headers = headers })
						if not response or response.status ~= 200 then
							error("Failed to fetch models: " .. tostring(response and response.status))
						end

						local models = {}
						for _, model in ipairs(vim.json.decode(response.body)["models"]) do
							table.insert(models, {
								id = model.name,
								name = model.name,
							})
						end
						return models
					end,

					get_selection = function(opts)
						if opts and opts.selection then
							-- vim.notify(
							-- 	"Selection being processed: " .. vim.inspect(opts.selection),
							-- 	vim.log.levels.DEBUG
							-- )
							return opts.selection
						end
						return nil
					end,

					prepare_input = function(inputs, opts)
						-- vim.notify("Inputs received: " .. vim.inspect(inputs), vim.log.levels.DEBUG)

						local messages = {}

						if inputs[1] and inputs[1].role == "system" then
							table.insert(messages, inputs[1])
						end

						if opts.selection then
							-- vim.notify("Selection found: " .. vim.inspect(opts.selection), vim.log.levels.DEBUG)
							table.insert(messages, {
								role = "system",
								content = string.format(
									"Selected code:\n```%s\n%s\n```\nFile: %s (lines %d-%d)",
									opts.selection.filetype or "",
									opts.selection.content,
									opts.selection.filename or "unknown",
									opts.selection.start_line or 0,
									opts.selection.end_line or 0
								),
							})
						end

						for _, input in ipairs(inputs) do
							if input.context then
								-- vim.notify("Context found: " .. vim.inspect(input.context), vim.log.levels.DEBUG)
								table.insert(messages, {
									role = "system",
									content = "Context: " .. input.context,
								})
							end
							if input.role ~= "system" then
								table.insert(messages, {
									role = input.role,
									content = input.content,
								})
							end
						end

						-- vim.notify("Final messages: " .. vim.inspect(messages), vim.log.levels.DEBUG)
						return {
							model = opts.model,
							messages = messages,
							stream = true,
						}
					end,

					get_url = function()
						return "http://localhost:11434/api/chat"
					end,
				},
			}

			options.prompts = {
				-- System prompts
				SystemPromptBase = {
					system_prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
				},
				SystemPromptReview = {
					system_prompt = table.concat({
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
						"",
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_review.md"),
					}, "\n"),
				},
				SystemPromptGeneration = {
					system_prompt = table.concat({
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_base.md"),
						"",
						load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/system_generate.md"),
					}, "\n"),
				},

				-- /Explain
				Explain = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain_en.md"),
					description = "Used to understand what the specified code is doing.",
				},
				ExplainInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/explain_ja.md"),
					description = "指定したコードが何をしているのかを理解するために使用します。",
				},

				-- /Review
				Review = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review_en.md"),
					description = "Used to perform a review for a given code.",
				},
				ReviewInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/review_ja.md"),
					description = "指定されたコードに対するレビューを行うために使用します。",
				},

				-- /Fix
				Fix = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix.md"),
					description = "It is used to fix problems (bugs and errors) occurring in the code.",
				},

				-- /Optimize
				Optimize = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/optimize.md"),
					description = "It is used to propose optimizations for improving the performance and readability of the code.",
				},

				-- /Docs
				Docs = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc_en.md"),
					description = "Used to generate detailed documentation for the provided code, including descriptions for functions, classes, arguments, and usage examples.",
				},
				DocsInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/doc_ja.md"),
					description = "指定したコードに対する詳細なドキュメントを作成するために使用します。",
				},

				-- /Tests
				Tests = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/tests.md"),
					description = "Used to create test cases for the provided code, covering critical paths, edge cases, and various test types.",
				},

				-- /FixDiagnostic
				FixDiagnostic = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/fix_diagnostic.md"),
					description = "Used to fix issues in the code based on diagnostic tool results, providing specific fixes and explanations.",
				},

				-- /Commit
				Commit = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_en.md"),
					description = "Used to create the appropriate commit message based on the current changes.",
				},
				CommitInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_ja.md"),
					description = "現在の変更内容に基づいて適切なコミットメッセージを作成するために使用します。",
					selection = function()
						if not cached_gitdiff then
							cached_gitdiff = select.gitdiff()
						end
						return cached_gitdiff
					end,
				},

				-- CommitStaged
				CommitStaged = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_staged_en.md"),
					description = "Used to create commit messages based on staged changes.",
					selection = function()
						if not cached_gitdiff then
							cached_gitdiff = select.gitdiff()
						end
						return cached_gitdiff
					end,
				},
				CommitStagedInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_staged_ja.md"),
					description = "ステージされた変更を基にコミットメッセージを作成するために使用します。",
					selection = function()
						if not cached_gitdiff then
							cached_gitdiff = select.gitdiff()
						end
						return cached_gitdiff
					end,
				},

				-- CommitMerge
				CommitPR = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request_en.md"),
					description = "Create a commit message based on the content of the PullRequest.",
				},
				CommitPRInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/commit_pull_request_ja.md"),
					description = "PullRequestの内容に基づいたコミットメッセージを作成します。",
				},

				-- Evaluation
				Evaluation = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation_en.md"),
					description = "Used to evaluate the quality, performance, and maintainability of the specified code, along with recommendations for improvement.",
				},
				EvaluationInJapanese = {
					prompt = load_prompt(vim.fn.stdpath("config") .. "/lua/plugins/prompts/evaluation_ja.md"),
					description = "指定されたコードの品質、性能、保守性を評価し、改善勧告を行うために使用します。",
				},

				-- Generate Pull Request
				GeneratePullRequest = {
					prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request_en.md"
					),
					description = "Generate pull request content.",
				},
				GeneratePullRequestInJapanese = {
					prompt = load_prompt(
						vim.fn.stdpath("config") .. "/lua/plugins/prompts/generate_pull_request_ja.md"
					),
					description = "PullRequestのコンテンツを生成する為に使用します。",
				},
			}

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
			}

			-- Window layout settings
			options.window = {
				layout = "float",
				relative = "cursor",
				width = 1,
				height = 0.7,
				row = 1,
			}
		end,
	},
}
