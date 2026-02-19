require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC> ", { noremap = true })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-------------------- User Config --------------------

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "General Clear highlights" })

map("n", "<C-h>", "<cmd> TmuxNavigateLeft<CR>")
map("n", "<C-l>", "<cmd> TmuxNavigateRight<CR>")
map("n", "<C-j>", "<cmd> TmuxNavigateDown<CR>")
map("n", "<C-k>", "<cmd> TmuxNavigateUp<CR>")

map("n", "<leader>db", "<cmd> DapToggleBreakpoint <CR>")

map("n", "<leader>dus", function()
  local widgets = require "dap.ui.widgets"
  local sidebar = widgets.sidebar(widgets.scopes)
  sidebar.open()
end, { desc = "dap-ui" })

map("n", "<leader>dpr", function()
  require("dap-python").test_method()
end, { desc = "debug-python" })

map("n", "<leader>dgt", function()
  require("dap-go").debug_test()
end, { desc = "debug-go" })

map("n", "<leader>dgl", function()
  require("dap-go").debug_test()
end, { desc = "debug-go-last" })

