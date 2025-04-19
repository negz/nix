local golang = require('neotest-golang')
local python = require('neotest-python')

require('neotest').setup {
	adapters = {
		golang {
			runner = "gotestsum",
			go_test_args = {
				"-v",
				"-race",
				"-coverprofile=/tmp/coverage.out",
			},
		},
		python,
	},
	output = { open_on_run = true },
	output_panel = { enabled = false },
	summary = { enabled = false },
	watch = { enabled = false },
	consumers = {
		notify = function(client)
			client.listeners.results = function(_, results, partial)
				if partial then
					return
				end

				local total = 0
				local passed = 0
				for _, r in pairs(results) do
					total = total + 1
					if r.status == "passed" then
						passed = passed + 1
					end
				end

				vim.notify(passed .. "/" .. total .. " tests passed.")
			end
		end,
	}
}
