local golang = require('neotest-golang')
local python = require('neotest-python')
local coverage = require('coverage')

local coverfile = function(name)
	return vim.fn.stdpath("cache") .. "/" .. name .. "-" .. tostring(vim.fn.getpid())
end

require('neotest').setup {
	adapters = {
		golang {
			runner = "gotestsum",
			go_test_args = {
				"-v",
				"-race",
				"-coverprofile=" .. coverfile("coverage-go"),
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

				coverage.load()

				vim.notify(passed .. "/" .. total .. " tests passed.")
			end
		end,
	}
}
