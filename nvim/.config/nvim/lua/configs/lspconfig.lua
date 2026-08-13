-- EXAMPLE
-- on_attach/on_init/capabilities are applied globally via
-- NvChad's M.defaults() -> vim.lsp.config("*", ...) + LspAttach autocmd.
-- Per-server we only need to enable; explicit config calls below document intent.

local servers = {
  "html",
  "cssls",
  "clangd",
  "ts_ls",
  "pyright",
  "gopls",
}

-- lsps with default config (inherits * defaults from NvChad)
for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {})
end

-- python: restrict to python filetype
vim.lsp.config("pyright", {
  filetypes = { "python" },
})

-- go: custom cmd, filetypes, root_markers, settings
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      completeUnimported = true,
      usePlaceholders = true,
      analyses = {
        unusedparams = true,
      },
    },
  },
})

-- enable all configured servers
vim.lsp.enable(servers)