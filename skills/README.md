# Skills

Single source of truth for agent skills. Each subfolder is either a git submodule (tracking an upstream skill repo) or a plain folder (your custom skills).

`script/setup_skills.sh` symlinks every skill into each agent's discovery dir so the same skill works in opencode, Claude Code, Codex, and any other `.agents/`-compatible tool.

## Layout

```
skills/
├── superpowers/           (submodule: obra/superpowers, pinned to release tag)
├── mattpocock-skills/     (submodule: mattpocock/skills)
├── caveman/               (submodule: juliusbrussee/caveman)
├── skill-tissue-skills/   (submodule: skill-tissue/skills — backseat, cvmn)
└── karpathy-guidelines/   (plain folder, your single SKILL.md)
```

## Setup on a new machine

After cloning the dotfiles repo:

```bash
bash ~/dotfiles/script/setup_skills.sh
```

This inits the submodules and symlinks every selected skill into:
- `~/.config/opencode/skills/`
- `~/.claude/skills/`
- `~/.codex/skills/`
- `~/.agents/skills/`

## Update skills to latest upstream

```bash
bash ~/dotfiles/script/setup_skills.sh --update
cd ~/dotfiles && git add skills/ && git commit -m "update skill submodules"
git push
```

Pull on other machines and rerun `setup_skills.sh` to apply the new pinned commits.

## Pin a submodule to a release tag

Superpowers ships tagged releases. To pin to a specific version:

```bash
cd ~/dotfiles/skills/superpowers
git fetch --tags
git checkout v6.2.0
cd ~/dotfiles
git add skills/superpowers
git commit -m "pin superpowers to v6.2.0"
git push
```

## Add a new skill from a mattpocock repo

1. Edit `MATTP0COCK_SKILLS` array in `~/dotfiles/script/setup_skills.sh`
2. Add the relative path under `skills/` (e.g. `engineering/improve-codebase-architecture`)
3. Rerun:

```bash
bash ~/dotfiles/script/setup_skills.sh
git add script/setup_skills.sh
git commit -m "add improve-codebase-architecture skill"
git push
```

## Add a skill from a new upstream repo

1. Add it as a submodule:

```bash
cd ~/dotfiles
git submodule add https://github.com/<owner>/<repo>.git skills/<name>
git commit -m "add <name> skill submodule"
```

2. Edit `script/setup_skills.sh`:
   - Add a new array (e.g. `NEWREPO_SKILLS=(all)` or list specific skill paths)
   - Add an `expand_source "<name>" "${NEWREPO_SKILLS[@]}"` line in the collection section

3. Rerun `setup_skills.sh`, commit, push.

## Add a custom skill you wrote

1. Create the folder + SKILL.md:

```bash
mkdir -p ~/dotfiles/skills/<my-skill>
$EDITOR ~/dotfiles/skills/<my-skill>/SKILL.md
```

2. SKILL.md must start with YAML frontmatter:

```yaml
---
name: my-skill
description: One-line description of what this skill does and when to use it.
---
```

Rules for `name`:
- 1-64 chars, lowercase alphanumeric + single hyphens
- Must match the folder name

3. Add `<my-skill>` to `CUSTOM_SKILLS` array in `script/setup_skills.sh`

4. Rerun `setup_skills.sh`, commit, push.

## Add a new agent to symlink to

Edit `AGENT_SKILL_DIRS` in `script/setup_skills.sh`:

```bash
AGENT_SKILL_DIRS=(
  "$HOME/.config/opencode/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.agents/skills"
  "$HOME/.config/some-new-agent/skills"   # add here
)
```

Rerun `setup_skills.sh`.

## What gets installed where

| Agent | Discovery path | Source |
|---|---|---|
| opencode | `~/.config/opencode/skills/<name>/SKILL.md` | symlink → `~/dotfiles/skills/<src>/...` |
| Claude Code | `~/.claude/skills/<name>/SKILL.md` | symlink → `~/dotfiles/skills/<src>/...` |
| Codex | `~/.codex/skills/<name>/SKILL.md` | symlink → `~/dotfiles/skills/<src>/...` |
| Generic `.agents/` | `~/.agents/skills/<name>/SKILL.md` | symlink → `~/dotfiles/skills/<src>/...` |

## Cross-OS notes

- **Linux/macOS**: `ln -sfn` for symlinks
- **Windows**: `mklink /J` for directory junctions (requires Developer Mode enabled or admin)
  - Enable Developer Mode: Settings → Update & Security → For Developers
- WSL: works like Linux

## Notes on rtk

If you use `rtk` (the AI-friendly shell wrapper from rtk-ai/rtk), note that `rtk find` does not support compound predicates (`-not`, `-exec`, `-delete`, etc.). For complex find operations, use `/usr/bin/find` directly. rtk is fine for basic commands like `rtk ls`, `rtk cat`, `rtk grep`.

## Removing a skill

1. Remove it from the corresponding array in `script/setup_skills.sh`
2. Rerun `setup_skills.sh` (existing symlinks for removed skills will be stale — delete them manually or run `setup_skills.sh --clean`)
3. For submodules you no longer want:

```bash
cd ~/dotfiles
git submodule deinit -f skills/<name>
git rm skills/<name>
git commit -m "remove <name> skill submodule"
```