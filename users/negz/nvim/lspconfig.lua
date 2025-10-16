local caps = require('blink.cmp').get_lsp_capabilities()

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = ' ',
			[vim.diagnostic.severity.WARN] = ' ',
			[vim.diagnostic.severity.HINT] = '󰌶 ',
			[vim.diagnostic.severity.INFO] = ' '
		},
	},
	virtual_lines = { current_line = true },
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	float = {
		scope = "cursor",
		focusable = false,
		border = "rounded",
		source = "always",
	},
})

-- Spelling and grammar
vim.lsp.config('harper_ls', {
	cmd = { 'harper-ls', '--stdio' },
	filetypes = { 'markdown', 'text', 'gitcommit' },
	root_markers = { '.git' },
	capabilities = caps,
	settings = {
		["harper-ls"] = {
			linters = {
				-- Gets mad about TODO(negz) markers.
				ToDoHyphen = false,

				-- Too many false positives, e.g. for private
				-- godoc and Go comment markers.
				SentenceCapitalization = false,

				-- Too sensitive to code and technical terms in
				-- comments. Prefer the typos spellchecker.
				SpellCheck = false,
			}
		}
	}
})

vim.lsp.config('typos_lsp', {
	cmd = { 'typos-lsp' },
	filetypes = { '*' },
	root_markers = { '.git' },
	capabilities = caps,
	init_options = {
		diagnosticSeverity = "Info"
	}
})


-- Nix
vim.lsp.config('nil_ls', {
	cmd = { 'nil' },
	filetypes = { 'nix' },
	root_markers = { 'flake.nix', 'flake.lock', '.git' },
	capabilities = caps,
	settings = {
		['nil'] = {
			formatting = { command = { "nixfmt" } },
			nix = {
				flake = {
					autoArchive = true
				}
			}
		}
	}
})

-- Lua, for configuring Neovim

vim.lsp.config('lua_ls', {
	cmd = { 'lua-language-server' },
	filetypes = { 'lua' },
	root_markers = { '.luarc.json', '.luarc.jsonc', '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml', '.git' },
	capabilities = caps,
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			format = {
				enable = true,
			}
		}
	}
})

-- Go

vim.lsp.config('gopls', {
	cmd = { 'gopls' },
	filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
	root_markers = { 'go.work', 'go.mod', '.git' },
	capabilities = caps,
	settings = {
		gopls = {
			gofumpt = true,
		},
	},
})

vim.lsp.config('golangci_lint_ls', {
	cmd = { 'golangci-lint-langserver' },
	filetypes = { 'go', 'gomod' },
	root_markers = { '.golangci.yml', '.golangci.yaml', '.golangci.toml', '.golangci.json', 'go.work', 'go.mod', '.git' },
	capabilities = caps,

	-- TODO(negz): Remove when the below issue is fixed.
	-- https://github.com/nametake/golangci-lint-langserver/issues/51
	init_options = (function()
		local pipe = io.popen("golangci-lint version|cut -d' ' -f4")
		if pipe == nil then
			return {}
		end
		local version = pipe:read("*a")
		pipe:close()
		local major_version = tonumber(version:match("^v?(%d+)%."))
		if major_version and major_version > 1 then
			return { command = { "golangci-lint", "run", "--output.json.path", "stdout", "--show-stats=false", "--issues-exit-code=1" } }
		end
		return { command = { "golangci-lint", "run", "--out-format", "json", "--show-stats=false", "--issues-exit-code=1" } }
	end)(),
})

-- Python

vim.lsp.config('basedpyright', {
	cmd = { 'basedpyright-langserver', '--stdio' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json', '.git' },
	capabilities = caps,
	settings = {
		-- Let Ruff handle all linting, formatting, and imports.
		basedpyright = {
			analysis = { ignore = { '*' } },
			disableOrganizeImports = true
		}
	}
})

vim.lsp.config('ruff', {
	cmd = { 'ruff', 'server' },
	filetypes = { 'python' },
	root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
	capabilities = caps,
})

-- Protobuf

vim.lsp.config('buf_ls', {
	cmd = { 'buf', 'beta', 'lsp' },
	filetypes = { 'proto' },
	root_markers = { 'buf.work.yaml', 'buf.yaml', '.git' },
	capabilities = caps,
})

-- Enable all configured LSP servers
vim.lsp.enable({
	'harper_ls',
	'typos_lsp',
	'nil_ls',
	'lua_ls',
	'gopls',
	'golangci_lint_ls',
	'basedpyright',
	'ruff',
	'buf_ls',
})

-- Format code on write.
vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		vim.lsp.buf.format({ opts = { timeout_ms = 3000 } })
	end
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.go",
	callback = function()
		-- TODO(negz): Is there a better way to discover encoding?
		local params = vim.lsp.util.make_range_params(0, "utf-16")
		params.context = { only = { "source.organizeImports" } }
		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
		for cid, res in pairs(result or {}) do
			for _, r in pairs(res.result or {}) do
				if r.edit then
					local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
					vim.lsp.util.apply_workspace_edit(r.edit, enc)
				end
			end
		end
	end
})
