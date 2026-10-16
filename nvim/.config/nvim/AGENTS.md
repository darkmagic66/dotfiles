# nvim config — agent notes

Guidance for this directory only (`~/.config/nvim` → `~/dotfiles/nvim/.config/nvim`).
The repo-root `agent.md` is a human runbook; OpenCode does not auto-load it
(lowercase `agent.md` is not a recognized instruction filename).

## Where things live

| What | Path | In repo? |
|---|---|---|
| Config source | `~/dotfiles/nvim/.config/nvim/` | yes |
| Live config | `~/.config/nvim` (symlink, stow package `nvim`) | — |
| Plugin specs | `lua/plugins/init.lua` | yes |
| Keymaps | `lua/mappings.lua`; full reference in `KEYMAPS.md` | yes |
| LSP server config | `lua/configs/lspconfig.lua` | yes |
| Formatters / linters | `lua/configs/null-ls.lua` | yes |
| Lockfile | `lazy-lock.json` | yes |
| Installed plugins | `~/.local/share/nvim/lazy/` | no |
| Installed tools | `~/.local/share/nvim/mason/` | no |
| Treesitter parsers / queries | `~/.local/share/nvim/site/{parser,queries}/` | no |

Base is NvChad on lazy.nvim. Because `~/.config/nvim` is a symlink, editing the
repo file *is* editing the live file; no copy step.

## Install model (read before editing plugin specs)

`mason.nvim` v2 **removed** `ensure_installed`. Adding it back does nothing.
Installs are split across two plugins, and each takes a different name space:

- `mason-lspconfig.nvim` → `ensure_installed` takes **nvim-lspconfig server
  names** (`html`, `cssls`, `ts_ls`, `lua_ls`, `pyright`, `gopls`, `clangd`,
  `jdtls`). Mason package names here warn "not a valid entry".
- `mason-tool-installer.nvim` → `ensure_installed` takes **mason package
  names** (`stylua`, `prettierd`, `black`, `gofumpt`, `debugpy`, …).

`automatic_enable = false` on mason-lspconfig is deliberate: enabling is driven
by `vim.lsp.enable(servers)` in `lua/configs/lspconfig.lua`. So a new language
server needs **both** edits — the server name in the plugin list, and the same
name in `servers` in `configs/lspconfig.lua`.

Installs only run in an interactive session (mason-lspconfig skips headless).
To install from a script use `:MasonInstall <package> ...`.

## Treesitter

`nvim-treesitter` here tracks the `main` branch, where `opts.ensure_installed`
alone installs nothing. Install is driven two ways:

- the plugin spec's `config` runs `require("nvim-treesitter").install(opts.ensure_installed)`
- `:TSInstallAll` (NvChad's command, reads the same list)

Parsers land in `site/parser`, queries in `site/queries` — outside the repo, so
a fresh machine depends on that install step running. Compiling needs the
`tree-sitter` CLI (>= 0.26.1, installed via brew).

## PATH trap (misleading errors)

NvChad prepends `<stdpath data>/mason/bin` to `vim.env.PATH`
(`nvchad/options.lua`), so mason binaries always shadow mise shims inside nvim.

If a mason package is missing, `vim.fn.exepath()` silently falls through to a
mise shim, and the server dies with:

```
mise ERROR No version is set for shim: vscode-html-language-server
```

That message means **the mason package is not installed** — not that mise is
broken. Check `~/.local/share/nvim/mason/bin` first.

Related: `~/dotfiles/mise.toml` also ships `npm:vscode-langservers-extracted`
(html/css/json/eslint/markdown servers). It is a second provisioning path; the
mason copies win on PATH.

## Java / Spring Boot

`jdtls` covers Java SE. Spring support is layered on top in three places:

- `lua/configs/lspconfig.lua` — lombok agent (`--jvm-arg=-javaagent:<mason>/jdtls/lombok.jar`,
  which the mason jdtls package already ships), `mvnw`/`pom.xml` root markers,
  `lombokSupport`, inlay hints (also enabled client-side on `LspAttach`), and the
  STS4 extension jars via `require("spring_boot").java_extensions()`.
- `plugins/init.lua` — `JavaHello/spring-boot.nvim` launches the Spring Boot
  language server. The jars alone are not enough: the server is a separate
  process, and nvim-jdtls-style classpath handshake commands must be registered
  too. The plugin discovers its paths from mason on its own.
- `lua/configs/dap.lua` — the Java debug adapter is jdtls itself
  (`vscode.java.startDebugSession`), plus launch configs built from
  `vscode.java.resolveMainClass` / `resolveClasspath`.

Vim-javaformating: `conform` uses `spring-javaformat` for `filetype=java`
(tabs, Spring's blank-line style). It reads stdin; its banner goes to stderr.

Plugin is `ft = "java"`: open a Java file once per session before expecting
`application.properties` / `.yml` completion.

Not wired: Java **test** keymaps. Running JUnit/TestNG through jdtls needs the
`vscode.java.test.*` command protocol plus parsing the runner's TCP results
(~600 lines in nvim-jdtls). `<leader>db`, `<leader>dgt`, `<leader>dpr` remain
Go/Python-only.

## Known gaps (verified, not yet fixed)

- `none-ls.nvim` is gated `ft = { "python", "go" }` in `lua/plugins/init.lua`,
  so `prettierd` never loads for html/css/js/ts.
- `configs/null-ls.lua`: `ruff` diagnostics commented out; format-on-save
  autocmd commented out.
- `nvim-lint` plugin block commented out in `lua/plugins/init.lua`.
- No LSP for JSON, YAML, or Markdown (treesitter only).

## Apply a change

1. Edit the file in `~/dotfiles/nvim/.config/nvim/`.
2. If plugin specs changed: `:Lazy sync` in nvim, then restart. Commit
   `lazy-lock.json` alongside.
3. If only options/mappings changed: restart nvim.

## Verify

Interactive: `:Lazy` (no load errors), `:Mason` (package installed),
`:checkhealth vim.lsp`.

Headless caveat: NvChad only emits `User FilePost` after `UIEnter`, and
nvim-lspconfig loads on that event. A bare headless run therefore shows zero
LSP clients. Set `vim.g.ui_entered` and re-fire the events:

```bash
nvim --headless foo.html \
  -c 'lua vim.g.ui_entered=true; vim.api.nvim_exec_autocmds("User",{pattern="FilePost"})' \
  -c 'sleep 1' \
  -c 'lua vim.api.nvim_exec_autocmds("FileType",{})' \
  -c 'sleep 6' \
  -c 'lua local b=vim.api.nvim_get_current_buf()
         print("ts="..tostring(vim.treesitter.highlighter.active[b]~=nil))
         for _,c in ipairs(vim.lsp.get_clients({bufnr=b})) do
           print("lsp="..c.name.." init="..tostring(c.initialized))
         end' \
  -c 'qa!'
```

Done when one `lsp=<server> init=true` line appears for the filetype and
`ts=true`. `ts=false` means the parser is missing; no `lsp=` line means either
the server is not installed or not enabled.
