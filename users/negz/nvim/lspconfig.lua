local lsp = require('lspconfig')
local caps = require('blink.cmp').get_lsp_capabilities()
local on_attach = function(client, bufnr)
	require('lsp-format').on_attach(client, bufnr)
end

vim.diagnostic.config({
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = ' ',
			[vim.diagnostic.severity.WARN] = ' ',
			[vim.diagnostic.severity.HINT] = '󰌶 ',
			[vim.diagnostic.severity.INFO] = ' '
		},
	},
	virtual_lines = true,
	update_in_insert = false,
	underline = true,
	severity_sort = true,
	float = {
		focusable = true,
		border = "rounded",
		source = "always",
	},
})

-- Spelling and grammar
lsp.harper_ls.setup {
	capabilities = caps,
	on_attach = on_attach,
	settings = {
		["harper-ls"] = {
			linters = {
				ToDoHyphen = false
			}
		}
	}
}

-- Nix
lsp.nil_ls.setup {
	capabilities = caps,
	on_attach = on_attach,
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
}

-- Lua, for configuring Neovim

lsp.lua_ls.setup {
	capabilities = caps,
	on_attach = on_attach,
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			format = {
				enable = true,
			}
		}
	}
}

-- Go

lsp.gopls.setup {
	capabilities = caps,
	on_attach = on_attach,
}

lsp.golangci_lint_ls.setup {
	capabilities = caps,
	on_attach = on_attach,

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
}

-- Python

lsp.basedpyright.setup {
	capabilities = caps,
	on_attach = on_attach,
	settings = {
		-- Let Ruff handle all linting, formatting, and imports.
		basedpyright = {
			analysis = { ignore = { '*' } },
			disableOrganizeImports = true
		}
	}
}

lsp.ruff.setup {
	capabilities = caps,
	on_attach = on_attach,
}
