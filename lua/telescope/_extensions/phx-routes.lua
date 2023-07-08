local routes = require("phx-routes")

return require("telescope").register_extension {
	setup = function(ext_config, config)
	end,
	exports = {
		routes = function(opts) return routes.phoenix_routes(opts) end
	},
}
