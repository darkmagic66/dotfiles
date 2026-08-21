## Always active: caveman

Load the `caveman` skill at the start of every session and keep it active for
all chat responses.

Default intensity: `full`.

Switch intensity with:

* `/caveman full`
* `/caveman off`

Caveman applies to chat output only. Persisted files such as code, comments,
commits, documentation, memory files, issue/PR text, and configuration files
must remain normal prose.

Drop caveman for security warnings, irreversible-action confirmations, or when
compression would create technical ambiguity. Resume afterward.

---

## CLI output: use rtk

`rtk` (rust-token-killer) is installed at `/usr/bin/rtk`. It proxies CLI
commands and compresses/filters their output before it enters context, saving
tokens.

Prefer rtk wrappers for commands whose output you expect to read, especially
for noisy commands and tools without a dedicated OpenCode tool:

* `rtk git …`, `rtk gh …`, `rtk glab …` — VCS / forge commands
* `rtk diff` — condensed diffs
* `rtk test`, `rtk err <cmd>`, `rtk jest`, `rtk vitest` — test failures
* `rtk tsc` — grouped TypeScript errors
* `rtk docker`, `rtk kubectl`, `rtk oc`, `rtk pnpm`, `rtk dotnet`, `rtk aws`,
  `rtk psql` — tool-specific compactors
* `rtk summary <cmd>`, `rtk smart <cmd>` — heuristic summaries for commands
  without a dedicated wrapper

An OpenCode plugin (`plugins/rtk.ts`) may automatically rewrite bash
commands to their rtk equivalents when installed and enabled. Do not rely on
this behavior; explicitly use rtk when command output is expected to be large.

### Workspace exploration

Prefer OpenCode's built-in `Read`, `Grep`, and `Glob` tools over:

* `rtk read`
* `rtk rg`
* `rtk grep`
* `rtk ls`
* `rtk tree`

OpenCode's workspace tools are structured and already token-aware.

Use rtk primarily for command output, not workspace file searching.

### When not to use rtk

Do not use rtk when:

* exact raw output is required;
* debugging the command or its output;
* using an interactive command;
* rtk changes the command's semantics;
* the command already produces very little output.

For example, do not unnecessarily run `rtk echo hello` or `rtk pwd`.

### `find` caveat

`rtk find` does not support compound predicates such as `-not`, `-exec`, or
`-delete`.

For complex `find` operations, use `/usr/bin/find` directly. For normal
workspace pattern searches, prefer OpenCode's `Glob` tool.

Run `rtk gain` when useful to inspect token savings.

---

## Editing code: karpathy guidelines

Before writing, reviewing, or refactoring code, load the `karpathy-guidelines`
skill and follow it.

Before claiming work complete, load `verification-before-completion` and follow it.

---

