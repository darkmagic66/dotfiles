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

map("n", "H", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer prev" })

map("n", "L", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer next" })

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

map("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "Toggle Zen Mode (Centered)" })

-------------------- Markdown --------------------
map("n", "<leader>mt", "<cmd>Markview toggle<CR>", { desc = "Markview toggle buffer" })
map("n", "<leader>mT", "<cmd>Markview Toggle<CR>", { desc = "Markview toggle global" })
map("n", "<leader>ms", "<cmd>Markview splitToggle<CR>", { desc = "Markview splitview" })
map("n", "<leader>mh", "<cmd>Markview HybridToggle<CR>", { desc = "Markview hybrid mode" })
map("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Browser preview toggle" })

