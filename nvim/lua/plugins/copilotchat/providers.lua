-- Define local providers for CopilotChat
local M = {}

M.providers = {

	-- Local Ollama
	ollama = {
		prepare_input = function(inputs, opts)
			local is_o1 = vim.startswith(opts.model.id, "o1")

			-- Insert a system message "/no_think" at the beginning of the inputs list.
			-- This message is used to instruct the CopilotChat provider to suppress internal reasoning or thinking steps.
			table.insert(inputs, 1, {
				role = "system",
				content = "/no_think",
			})

			inputs = vim.tbl_map(function(input)
				if is_o1 then
					if input.role == "system" then
						input.role = "user"
					end
				end

				return input
			end, inputs)

			local out = {
				messages = inputs,
				model = opts.model.id,
			}

			if not is_o1 then
				out.n = 1
				out.top_p = 1
				out.stream = true
				out.temperature = opts.temperature
			end

			if opts.model.max_output_tokens then
				out.max_tokens = opts.model.max_output_tokens
			end

			return out
		end,

		prepare_output = function(output)
			local references = {}

			if output.copilot_references then
				for _, reference in ipairs(output.copilot_references) do
					local metadata = reference.metadata
					if metadata and metadata.display_name and metadata.display_url then
						table.insert(references, {
							name = metadata.display_name,
							url = metadata.display_url,
						})
					end
				end
			end

			local message
			if output.choices and #output.choices > 0 then
				message = output.choices[1]
			else
				message = output
			end

			local content = message.message and message.message.content or message.delta and message.delta.content

			-- Remove <think> tags and leading whitespace from the content string, if present.
			if content then
				content = content:gsub("<think>", ""):gsub("</think>", ""):gsub("^%s+", "")
			end

			local usage = message.usage and message.usage.total_tokens or output.usage and output.usage.total_tokens

			local finish_reason = message.finish_reason
				or message.done_reason
				or output.finish_reason
				or output.done_reason

			return {
				content = content,
				finish_reason = finish_reason,
				total_tokens = usage,
				references = references,
			}
		end,

		get_models = function(headers)
			local response, err = require("CopilotChat.utils").curl_get("http://localhost:11434/v1/models", {
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
			local response, err = require("CopilotChat.utils").curl_post("http://localhost:11434/v1/embeddings", {
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

return M
