-- nvdash j/k crash workaround (upstream nvchad/ui v3.0@6ced113).
-- The plugin maps j/k to nvim_win_set_cursor(win, key_movements(...)), but
-- key_movements returns NOTHING when the cursor sits on a non-button line
-- (header, blank gap, or anywhere reached via mouse click, scroll, gg/G,
-- search). The missing 2nd arg makes the API call fail with:
--   E5108: ... nvdash/init.lua:214: Expected 2 arguments
-- No fix exists upstream (v3.0 HEAD == pinned commit), so wrap the plugin's
-- buffer-local j/k/<up>/<down> after they are defined (they are set before
-- the buffer gets filetype=nvdash): on failure, fall back to plain motion.
-- Revisit/remove once upstream guards the nil return.
local group = vim.api.nvim_create_augroup("NvdashJKWorkaround", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "nvdash",
  desc = "guard nvdash j/k against off-button cursor (E5108)",
  callback = function(ev)
    local buf = ev.buf
    -- index the buffer's Lua-callback mappings by (lowercased) lhs
    local by_lhs = {}
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
      if type(m.callback) == "function" and type(m.lhs) == "string" then
        by_lhs[m.lhs:lower()] = m.callback
      end
    end
    local fallbacks = { j = "j", k = "k", ["<down>"] = "j", ["<up>"] = "k" }
    for _, key in ipairs({ "j", "k", "<down>", "<up>" }) do
      local orig = by_lhs[key:lower()]
      if orig then
        local motion = fallbacks[key]
        vim.keymap.set("n", key, function()
          local ok = pcall(orig)
          if not ok then
            vim.cmd("normal! " .. motion)
          end
        end, { buffer = ev.buf, silent = true, desc = "nvdash move (E5108-guarded)" })
      end
    end
  end,
})
