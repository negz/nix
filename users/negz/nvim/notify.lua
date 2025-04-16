local notify = require('notify')

notify.setup({
	fps = 120
})

vim.notify = notify
