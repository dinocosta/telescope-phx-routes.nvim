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
				-- Since we know that every line that is output from `mix phx.routes` follows the same pattern we can easily
				-- leverage Lua's patterns to match on the parts we care about.
				-- The format of the line output from `mix phx.routes` is:
				--
				-- [WHITESPACE][PATH][WHITESPACE][METHOD][WHITESPACE][URL][WHITESPACE][CONTROLLER][WHITESPACE][ACTION]
				-- 
				-- For example:
				--
				--     api_v1_path   GET   /api/v1/users   AppWeb.API.V1.UserCotntroller   :index
				--
				-- We can match multiple whitespace characters with the `%s+` character class, while using `%S+` yields the 
				-- opposite result, i.e., matches on all characters except the space character, which should help 
				-- understand the string used in the `match` function below.
				local path, method, url, controller, action = line:match('(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)')

				return {
					value = { path = path, method = method, url = url, controller = controller, action = action},
					display = table.concat({ method, " ", url }),
					ordinal = table.concat({ method, " ", url })
				}
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
				local handle = io.popen("mix phx.routes --info " .. selection["value"]["url"])
				local result = handle:read("*a")
				handle:close()
				local file_path, line_number = result:match('Module: %S+\nFunction: %S+\n(%S+):(%d+)')

				-- Open the file where the controller module for the route is defined.
				vim.cmd('e ' .. file_path)
			end)

			return true
		end,
	}):find()
end

return M
