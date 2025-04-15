colorful = require('colorful-menu')

require('blink.cmp').setup {
	keymap = { preset = 'super-tab' },
	completion = {
		list = {
			selection = {
				preselect = false,
			},
		},
		menu = {
			border = 'rounded',
			draw = {
				columns = { { "kind_icon" }, { "label", gap = 1 } },
				components = {
					label = {
						text = function(ctx)
							return colorful.blink_components_text(ctx)
						end,
						highlight = function(ctx)
							return colorful.blink_components_highlight(ctx)
						end,
					},
				},
			},
		}
	},
	sources = {
		default = { 'lsp', 'path', 'avante' },
		providers = {
			avante = {
				module = 'blink-cmp-avante',
				name = 'Avante',
			},
		},
	},
	fuzzy = { implementation = "rust" },
	signature = {
		enabled = true,
		window = {
			show_documentation = true,
			border = 'rounded',
			direction_priority = { 's', 'n' }
		},
	}
}
