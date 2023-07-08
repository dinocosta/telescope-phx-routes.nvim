return require("telescope").register_extension {
	setup = function(ext_config, config)
	end,
	exports = {
		phx_routes = require("phx_routes").phoenix_routes
	},
}
