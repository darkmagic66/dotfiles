local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local null_ls = require "null-ls"

local b = null_ls.builtins

local opts = {
  sources = {
    b.formatting.prettierd,
    
    b.diagnostics.mypy,
    -- b.diagnostics.ruff,
    b.formatting.black,

    b.formatting.gofumpt,
    b.formatting.goimports,
    -- b.formatting.goimports_reviser,
    b.formatting.golines,
  },
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({
      group = augroup,
      buffer = bufnr,
    })
    -- format on save
    -- vim.api.nvim_create_autocmd("BufWritePre", {
    --   group = augroup,
    --   buffer = bufnr,
    --   callback = function()
    --   vim.lsp.buf.format({ bufnr = bufnr})
    --   end,
    -- })
    end
  end,
}
-- return opts
