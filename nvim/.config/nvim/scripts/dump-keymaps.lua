-- Regenerates the keymap tables in KEYMAPS.md from the live keymap table.
--
-- Run from the dotfiles repo:
--   nvim --headless -c "lua dofile('nvim/.config/nvim/scripts/dump-keymaps.lua')" -c 'qa!'
--
-- `nvim -l` cannot be used: it does not load the user config, so no mappings
-- exist yet. Everything between the BEGIN/END GENERATED markers in KEYMAPS.md is
-- replaced; the prose outside them is left byte-identical.
--
-- Source attribution: Lua-defined mappings carry no usable script id
-- (maparg().sid is -8 for them, and getscriptinfo rejects negative ids), so a
-- mapping is labelled "repo" when its quoted lhs appears in this config's Lua
-- files, and "default" otherwise (NvChad, a plugin, or Neovim itself).

local md_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h") .. "/KEYMAPS.md"
local cfg_dir = vim.fn.fnamemodify(md_path, ":h")

local BEGIN_MARK = "<!-- BEGIN GENERATED: keymap tables -->"
local END_MARK = "<!-- END GENERATED -->"

-- The config loads lazily; wait until a known mapping exists.
local waited = 0
while vim.fn.maparg("<leader>ch", "n") == "" and waited < 20000 do
  vim.wait(200)
  waited = waited + 200
end
if vim.fn.maparg("<leader>ch", "n") == "" then
  io.stderr:write("config never finished loading, aborting\n")
  os.exit(1)
end

-- Config sources, for the "repo" bucket. Whitespace is stripped so the search
-- can require the "," that precedes a keymap's lhs argument, which rules out
-- unrelated literals such as a `pattern = "*"` autocmd.
-- Vim stores modifier keys upper-cased (`<C-h>` comes back as `<C-H>`), so key
-- notation is lower-cased on both sides. Only text inside <> is touched: a bare
-- `H` and `h` are different keys and must not be conflated.
local function normalize_key(text)
  return (text:gsub("<([^>]*)>", function(inner)
    return "<" .. inner:lower() .. ">"
  end))
end

local source_lines = {}
for _, file in ipairs(vim.fn.glob(cfg_dir .. "/**/*.lua", false, true)) do
  for _, line in ipairs(vim.fn.readfile(file)) do
    -- Drop comments, so a commented-out mapping is not counted as a real one.
    source_lines[#source_lines + 1] = normalize_key(line:gsub("%-%-.*$", ""):gsub("%s+", ""))
  end
end

-- A mapping is "repo" when one of the config's Lua lines maps that exact key in
-- that exact mode. The mode check matters: `<C-h>` is tmux navigation in normal
-- mode (this repo) and cursor-left in insert mode (NvChad), same lhs, different
-- owner.
local function is_repo_map(modes, lhs)
  local needle = normalize_key(lhs)
  for _, line in ipairs(source_lines) do
    if line:find(',"' .. needle .. '"', 1, true) or line:find(",'" .. needle .. "'", 1, true) then
      for _, mode in ipairs(modes) do
        if line:find('"' .. mode .. '"', 1, true) then
          return true
        end
      end
    end
  end
  return false
end

-- Modes are dumped in this order. Visual and select are merged, because the same
-- mapping is usually registered for both and would otherwise appear twice.
local mode_groups = {
  { id = "n", label = "Normal", modes = { "n" } },
  { id = "i", label = "Insert", modes = { "i" } },
  { id = "vx", label = "Visual / Select", modes = { "v", "x" } },
  { id = "t", label = "Terminal", modes = { "t" } },
  { id = "o", label = "Operator-pending", modes = { "o" } },
  { id = "s", label = "Select", modes = { "s" } },
}

local function action_of(entry)
  if entry.desc and entry.desc ~= "" then
    return entry.desc
  end
  if entry.callback then
    return "<lua>"
  end
  return entry.rhs or ""
end

local function escape(text)
  return (text:gsub("|", "\\|"))
end

-- nvim_get_keymap returns the leader already expanded to its literal key, so
-- "<leader>m" comes back as " m". Put the name back for display and for the
-- source search, which looks for the literal as written in the config files.
local leader = vim.g.mapleader or "\\"
local function display_key(lhs)
  if leader ~= "" and lhs:sub(1, #leader) == leader then
    return "<leader>" .. lhs:sub(#leader + 1)
  end
  return lhs
end

local rows = {}
local skipped = {}
for _, group in ipairs(mode_groups) do
  local seen = {}
  local lines = {}
  for _, mode in ipairs(group.modes) do
    for _, entry in ipairs(vim.api.nvim_get_keymap(mode)) do
      local action = action_of(entry)
      local shown = display_key(entry.lhs)
      -- A callback with no description is an internal stub, not a binding the
      -- user can act on: lazy.nvim installs one per lazy-loaded key to trigger
      -- the load, and it passes the key through to its normal meaning. Give a
      -- mapping a `desc` and it appears here.
      if (entry.desc == nil or entry.desc == "") and entry.callback then
        skipped[#skipped + 1] = mode .. " " .. shown
      else
        local key = shown .. "\t" .. action
        if not seen[key] then
          seen[key] = { lhs = entry.lhs, shown = shown, action = action, modes = { mode } }
          lines[#lines + 1] = seen[key]
        else
          table.insert(seen[key].modes, mode)
        end
      end
    end
  end
  table.sort(lines, function(a, b)
    return a.shown < b.shown
  end)
  rows[#rows + 1] = { label = group.label, lines = lines }
end

local out = {}
out[#out + 1] = BEGIN_MARK
out[#out + 1] = ""
out[#out + 1] = "<!-- Generated by scripts/dump-keymaps.lua - do not edit this region by hand. -->"
for _, group in ipairs(rows) do
  if #group.lines > 0 then
    out[#out + 1] = ""
    out[#out + 1] = "### " .. group.label
    out[#out + 1] = ""
    out[#out + 1] = "| Key | Action | Source |"
    out[#out + 1] = "|---|---|---|"
    for _, line in ipairs(group.lines) do
      out[#out + 1] = string.format(
        "| `%s` | %s | %s |",
        escape(line.shown),
        escape(line.action),
        is_repo_map(line.modes, line.shown) and "repo" or "default"
      )
    end
  end
end
out[#out + 1] = ""
out[#out + 1] = END_MARK

local original = vim.fn.readfile(md_path)
local begin_at, end_at
for i, line in ipairs(original) do
  if line:find(BEGIN_MARK, 1, true) then
    begin_at = i
  elseif line:find(END_MARK, 1, true) and begin_at then
    end_at = i
    break
  end
end

if not begin_at or not end_at then
  io.stderr:write("markers not found in " .. md_path .. "\n")
  os.exit(1)
end

local result = {}
vim.list_extend(result, { unpack(original, 1, begin_at - 1) })
vim.list_extend(result, out)
vim.list_extend(result, { unpack(original, end_at + 1) })
vim.fn.writefile(result, md_path)

io.stderr:write(
  string.format("wrote %d rows across %d mode groups to %s\n", (function()
    local n = 0
    for _, g in ipairs(rows) do
      n = n + #g.lines
    end
    return n
  end)(), #rows, md_path)
)
if #skipped > 0 then
  io.stderr:write(string.format("filtered %d undescribed stubs: %s\n", #skipped, table.concat(skipped, ", ")))
end
