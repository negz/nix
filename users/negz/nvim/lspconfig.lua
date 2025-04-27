local lsp = require('lspconfig')
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
lsp.harper_ls.setup {
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
}

lsp.typos_lsp.setup {
	capabilities = caps,
	init_options = {
		diagnosticSeverity = "Info"
	}
}


-- Nix
lsp.nil_ls.setup {
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
}

-- Lua, for configuring Neovim

lsp.lua_ls.setup {
	capabilities = caps,
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
	settings = {
		gopls = {
			gofumpt = true,
		},
	},
}

lsp.golangci_lint_ls.setup {
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
}

-- Python

lsp.basedpyright.setup {
	capabilities = caps,
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
}

-- Protobuf

lsp.buf_ls.setup {
	capabilities = caps,
}

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
