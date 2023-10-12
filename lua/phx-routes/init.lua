local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}

M.phoenix_routes = function(opts)
	opts = opts or {}

	pickers.new(opts, {
		prompt_title = "Phoenix Routes",
		finder = finders.new_oneshot_job({ "mix", "phx.routes" }, {
			entry_maker = function(line)
				-- The `mix phx.routes` command always prints an empty line at the end, as such, we have to make sure we ignore
				-- that line successfully, otherwise Telescope will consider it an entry too.
				if line ~= '' then
					-- Since we know that every line that is output from `mix phx.routes` follows the same pattern we can easily
					-- leverage Lua's patterns to match on the parts we care about.
					-- The format of the line output from `mix phx.routes` is:
					--
					-- [WHITESPACE][PATH][WHITESPACE][METHOD][WHITESPACE][URL][WHITESPACE][CONTROLLER][WHITESPACE][ACTION]
					-- 
					-- For example:
					--
					--     api_v1_path   GET   /api/v1/users   AppWeb.API.V1.UserController   :index
					--
					-- We can match multiple whitespace characters with the `%s+` character class, while using `%S+` yields the 
					-- opposite result, i.e., matches on all characters except the space character, which should help 
					-- understand the string used in the `match` function below.
					local path, method, url, controller, action = line:match('(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)')

					-- If path is nil it means that this route actually does not have a path defined, so we should try to match
					-- instead on only the method, url, controller and action.
					if path == nil then
						method, url, controller, action = line:match('(%S+)%s+(%S+)%s+(%S+)%s+(%S+)')
					end

					-- If method is nil it means that this route is likely a LiveView route, which does not have an action, matching
					-- only on the method, url and controller will give us the intended result.
					if method == nil then
						method, url, controller = line:match('(%S+)%s+(%S+)%s+(%S+)')
					end

					-- I tried using both `table.concat` as well as the string concatenation operator (`..`) in the table returned
					-- by this function and found that, only when using `table.concat` and assigning to a variable, could I get
					-- the results to consistently appear in the results list. Using any other option would usually result in
					-- results only being shown after the user started typing in the search box.
					local result = table.concat({ method, " ", url })

					return {
						value = { path = path, method = method, url = url, controller = controller, action = action},
						display = result,
						ordinal = result
					}
				end
			end
		}),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(function()
				actions.close(prompt_bufnr)

				-- The `selection` variable will be set to the result returned by the `entry_maker` function. 
				-- As such, if you need to access, for example, the `url` value you can use `selection["value"]["url"]`.
				-- You can always use `print(vim.inspect(selection))` to inspect the `selection` variable and what it contains.
				local selection = action_state.get_selected_entry()

				-- Start a new process to run the `mix phx.routes --info [URL]` command and get its output.
				-- Match on the output of the command so we can get the file path.
				local handle = io.popen("mix phx.routes --info " .. selection["value"]["url"] .. " --method " .. selection["value"]["method"])
				local result = handle:read("*a")
				handle:close()
				local file_path, line_number = result:match('Module: %S+\nFunction: %S+\n(%S+):(%d+)')

				-- Open the file where the controller module for the route is defined, as well as setting the cursor in the 
				-- correct line, which, unfortunately only works for `GET` calls, as `mix phx.routes --info` does not allow 
				-- us to specify what is the HTTP method, so it can not differentiate between, say, the `:index` and `:delete` 
				-- actions.
				vim.api.nvim_command('e ' .. file_path)
				vim.api.nvim_command('exe ' .. line_number)
			end)

			return true
		end,
	}):find()
end

return M
