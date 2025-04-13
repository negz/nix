local lsp = require('lspconfig')
local caps = require('blink.cmp').get_lsp_capabilities()

-- Lua, for configuring NeoVim

lsp.lua_ls.setup {
  capabilities = caps,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } }
    }
  }
}

-- Go

lsp.gopls.setup {
  capabilities = caps,
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
          return {command = {"golangci-lint", "run", "--output.json.path", "stdout", "--show-stats=false", "--issues-exit-code=1"}}
      end
      return {}
  end)(),
}

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    vim.lsp.buf.format({async = false})
  end
})

