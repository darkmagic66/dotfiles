# Keymaps

Leader is **Space**. Local leader is unset.

Three ways to browse them live:

- `<leader>ch` — NvCheatsheet (grid of every binding)
- `<leader>wk` — which-key query for a prefix
- `<leader>wK` — which-key, all keymaps

## Where they come from

| Source | File | In repo |
|---|---|---|
| NvChad defaults | `~/.local/share/nvim/lazy/NvChad/lua/nvchad/mappings.lua` | no |
| Your overrides | `lua/mappings.lua` | yes |
| Dashboard buttons | `lua/chadrc.lua` (`M.nvdash.buttons`) | yes |
| Plugin defaults | LSP (Neovim builtin), treesitter textobjects, conform, nvim-dap, vim-tmux-navigator | no |

"repo" below means `lua/mappings.lua`; "NvChad" means the plugin's own defaults.
Later maps win, so a repo map overrides an NvChad one on the same key.

Modes: `n` normal · `i` insert · `v`/`x` visual · `t` terminal · `s` select ·
`o` operator-pending · `i,v` = both.

## Core editing

| Key | Mode | Action | Source |
|---|---|---|---|
| `<leader>` | — | leader (Space) | — |
| `;` | n | command mode (`:`) | repo |
| `<Esc>` | n | clear search highlight | both |
| `jk` | i | leave insert mode | repo |
| `<C-s>` | n | save file | NvChad |
| `<C-c>` | n | yank whole file to clipboard | NvChad |
| `<leader>fm` | n, x | format file (conform, LSP fallback) | NvChad |
| `<leader>/` | n, v | toggle comment | NvChad |
| `gcc` / `gc` | n | comment line / toggle comment | treesitter |
| `<leader>n` / `<leader>rn` | n | toggle absolute / relative line numbers | NvChad |
| `Y` | n | yank to end of line | Neovim 0.11+ |

## Buffers (tabufline)

| Key | Mode | Action | Source |
|---|---|---|---|
| `<Tab>` / `<S-Tab>` | n | next / previous buffer | NvChad |
| `H` / `L` | n | previous / next buffer | repo |
| `<leader>x` | n | close buffer | NvChad |
| `<leader>b` | n | new buffer (`:enew`) | NvChad |

## Windows and tmux

| Key | Mode | Action | Source |
|---|---|---|---|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | n, t | tmux pane left / down / up / right | repo + tmux-navigator |
| `<C-h>` / `<C-l>` | i | cursor left / right | NvChad |
| `<C-j>` / `<C-k>` | i | menu open: select next / previous suggestion; closed: cursor down / up | repo (cmp) over NvChad |
| `<C-b>` | i | beginning of line | NvChad |
| `<C-e>` | i | end of line | NvChad |
| `<C-\>` | n | previous tmux pane | vim-tmux-navigator |

Normal-mode `<C-h>`/`<C-l>` are tmux navigation and therefore replace NvChad's
`<C-w>h` / `<C-w>l` window maps. In insert mode the same keys do cursor motion,
except `<C-j>`/`<C-k>`, which select completions first — see Completion below.

## Find (telescope)

| Key | Action |
|---|---|
| `<leader>ff` | find files |
| `<leader>fa` | find all files (hidden, no ignore, follow) |
| `<leader>fw` | live grep |
| `<leader>fb` | open buffers |
| `<leader>fh` | help tags |
| `<leader>fo` | recent files (oldfiles) |
| `<leader>fz` | fuzzy find in current buffer |
| `<leader>ma` | marks |
| `<leader>cm` | git commits |
| `<leader>gt` | git status |
| `<leader>pt` | hidden terminals |
| `<leader>th` | themes |

## File tree (nvimtree)

| Key | Action |
|---|---|
| `<C-n>` | toggle file tree |
| `<leader>e` | focus file tree |

## Terminal

| Key | Mode | Action |
|---|---|---|
| `<leader>h` | n | new horizontal terminal |
| `<leader>v` | n | new vertical terminal |
| `<A-h>` / `<A-v>` / `<A-i>` | n, t | toggle horizontal / vertical / floating terminal |
| `<C-x>` | t | leave terminal mode |

## LSP

| Key | Mode | Action |
|---|---|---|
| `grn` | n | rename symbol |
| `gra` | n, v, x | code action |
| `gri` | n | implementations |
| `grr` | n | references |
| `grt` | n | type definition |
| `gO` | n | document symbols |
| `grx` | n | run codelens |
| `<C-s>` | i | signature help |
| `<leader>ds` | n | diagnostics to location list |
| `]d` / `[d` | n | next / previous diagnostic |
| `]D` / `[D` | n | last / first diagnostic |
| `<C-w>d` | n | diagnostics under cursor |

## Completion (nvim-cmp)

Active once cmp attaches on `InsertEnter`.

| Key | Action |
|---|---|
| `<C-j>` / `<C-k>` | select next / previous suggestion; falls back to cursor down / up when the menu is closed |
| `<C-n>` / `<C-p>` | select next / previous, opening the menu when it is closed |
| `<Tab>` / `<S-Tab>` | next / previous suggestion, else LuaSnip expand / jump |
| `<CR>` | confirm selection |
| `<C-e>` | close the menu |
| `<C-d>` / `<C-f>` | scroll docs down / up |
| `<C-Space>` | trigger completion manually |

`<C-j>`/`<C-k>` work because cmp replaces NvChad's cursor maps on `InsertEnter`
and keeps the old maps as the fallback (`cmp.core:prepare` → `keymap.listen`).

## Treesitter textobjects

| Key | Mode | Action |
|---|---|---|
| `]n` / `[n` | n, v, x | next / previous node |
| `]N` / `[N` | v, x | next / previous sibling |
| `an` / `in` | v, x, o | parent (outer) / child (inner) node |
| `<Tab>` / `<S-Tab>` | i, v, s | snippet jump, else indent/tab |

## Debug (nvim-dap)

| Key | Action |
|---|---|
| `<leader>db` | toggle breakpoint |
| `<leader>dus` | open scopes sidebar (dap-ui) |
| `<leader>dgt` | debug Go test |
| `<leader>dgl` | re-run the last Go test (`debug_last_test`) |
| `<leader>dpr` | debug Python test method |

## Markdown and preview

| Key | Action |
|---|---|
| `<leader>mt` | markview toggle (buffer) |
| `<leader>mT` | markview toggle (global) |
| `<leader>ms` | markview split view |
| `<leader>mh` | markview hybrid mode |
| `<leader>mp` | browser preview toggle |

## Misc

| Key | Action |
|---|---|
| `<leader>z` | zen mode |
| `<leader>ob` | open current file with the system handler (`vim.ui.open`) |
| `<leader>wk` / `<leader>wK` | which-key query / all |
| `<leader>ch` | NvCheatsheet |
| `gx` | open URI or path under cursor |

## Dashboard (nvdash buffer only)

Buttons from `lua/chadrc.lua`; these keys are buffer-local.

| Key | Action |
|---|---|
| `ff` | find files |
| `fo` | recent files |
| `fw` | find word |
| `ma` | bookmarks (marks) |
| `th` | themes |
| `ch` | mappings (NvCheatsheet) |
| `<CR>` | activate button under cursor |
| `j` `k` `↓` `↑` | move between buttons (extra guarded, see `lua/autocmds.lua`) |

## Neovim / plugin defaults worth knowing

| Key | Action |
|---|---|
| `[ ` / `] ` | add empty line above / below |
| `[b` `]b` | previous / next buffer |
| `[l` `]l` | previous / next location-list entry |
| `[q` `]q` | previous / next quickfix entry |
| `[t` `]t` | previous / next tag |
| `&` | repeat substitute on line |
| `gf` `gg` `G` | standard Neovim |

## Known oddities

- **`<C-h/j/k/l>` are overloaded by mode.** Insert = cursor motion, and
  `<C-j>`/`<C-k>` also drive completion selection while the menu is open.
  Normal and terminal = tmux pane navigation. Consequence: `<C-h>` no longer
  backspaces in insert mode (use `<BS>`).
- **Formatting is split across two systems.** `<leader>fm` uses conform (NvChad
  default, LSP fallback); none-ls handles prettierd/black/gofumpt but is
  ft-gated to `python` and `go`, and format-on-save is off. See `AGENTS.md`.
