local colorful = require('colorful-menu')

require('blink.cmp').setup {
	keymap = {
		preset = 'super-tab',
		['<CR>'] = { 'accept', 'fallback' },
	},
	completion = {
		list = {
			selection = {
				preselect = false,
				auto_insert = false,
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
		},
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 0,
		},
		ghost_text = {
			enabled = true,
		},
	},
	sources = {
		default = { 'lsp', 'omni', 'path' },
	},
	fuzzy = { implementation = "rust" },
	signature = {
		enabled = true,
		window = {
			show_documentation = true,
			border = 'rounded',
			scrollbar = true,
		},
	},
}
