require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>", { noremap = true })

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
  require("dap-go").debug_last_test()
end, { desc = "debug-go-last" })

map("n", "<leader>z", "<cmd>ZenMode<CR>", { desc = "Toggle Zen Mode (Centered)" })

map("n", "<leader>ob", function()
  vim.ui.open(vim.fn.expand "%:p")
end, { desc = "Open file in browser" })

-------------------- Markdown --------------------
map("n", "<leader>mt", "<cmd>Markview toggle<CR>", { desc = "Markview toggle buffer" })
map("n", "<leader>mT", "<cmd>Markview Toggle<CR>", { desc = "Markview toggle global" })
map("n", "<leader>ms", "<cmd>Markview splitToggle<CR>", { desc = "Markview splitview" })
map("n", "<leader>mh", "<cmd>Markview HybridToggle<CR>", { desc = "Markview hybrid mode" })
map("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", { desc = "Browser preview toggle" })

-------------------- Paths --------------------
local function copy_path(path)
  if path == "" then
    vim.notify("No file name to copy", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", path, "v")
  vim.notify("Copied: " .. path)
end

map("n", "<leader>n", function()
  copy_path(vim.fn.expand "%:.")
end, { desc = "Copy relative path" })

map("n", "<leader>m", function()
  copy_path(vim.fn.expand "%:p")
end, { desc = "Copy absolute path" })

-- NvChad's default <leader>n (toggle line number) moved here so the relative
-- path copy above can take that key.
map("n", "<leader>tn", "<cmd>set nu!<CR>", { desc = "Toggle line number" })

-------------------- Git --------------------
-- <leader>gd opens, focuses, or closes the diff view; <leader>gD shows file
-- history for the current buffer. `require` sits inside the callbacks so
-- diffview stays command-lazy and only loads on first use.
local function toggle_diffview()
  local lib = require "diffview.lib"

  if lib.get_current_view() then
    vim.cmd "DiffviewClose"
    return
  end

  local other = lib.views[1]
  if other then
    vim.api.nvim_set_current_tabpage(other.tabpage)
    return
  end

  vim.cmd "DiffviewOpen"
end

map("n", "<leader>gd", toggle_diffview, { desc = "Git diffview toggle" })

map("n", "<leader>gD", function()
  vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(vim.fn.expand "%"))
end, { desc = "Git file history for buffer" })

