AI Skills Management — Migration Plan

Goal

Refactor the current AI-agent skill management in my dotfiles so that:

Personal skills remain fully Git-controlled.

Third-party skills can be installed/updated using the npx skills ecosystem.

dotfiles remains the source of truth for which skills should be installed.

Multiple AI agents can consume the same canonical skill directory.

A new machine can reproduce the complete setup easily.

Avoid unnecessary Git submodules and custom Git-clone logic.

Keep the system simple and keyboard/CLI friendly.

Current agents include:

OpenCode

GitHub Copilot CLI

Potentially other agents in the future

Current System

Currently I have something approximately like:

dotfiles/
└── skills/
    ├── external skills
    ├── personal skills
    └── git submodules

External skills are commonly cloned from GitHub, for example:

Superpowers

Matt Pocock / Ponytail

Other community skills

Personal skills are written and maintained by me.

I then expose the skills to different AI agents using symlinks.

There are also custom scripts for:

listing skills

cloning skills

updating/managing skills

This works, but the custom Git/submodule management is becoming unnecessary overhead.

Proposed Architecture

Use a hybrid model.

dotfiles/
└── ai/
    ├── skills/
    │   ├── personal/
    │   │   ├── skill-a/
    │   │   ├── skill-b/
    │   │   └── ...
    │   │
    │   └── external/
    │       ├── superpowers/
    │       ├── ponytail/
    │       └── ...
    │
    ├── skills.yaml
    ├── skills.lock
    └── scripts/
        └── ...

The exact directory names can be adjusted to fit the existing dotfiles structure.

Ownership model

Personal skills

Personal skills are owned directly by the dotfiles repository.

ai/skills/personal/

They should be:

normal Git-tracked files

edited directly

versioned with the dotfiles repository

reproducible on another machine

Do NOT install personal skills through an external package manager unless there is a strong reason.

External skills

Third-party skills should be managed through the skills installer/ecosystem where practical.

Examples:

superpowers
ponytail
other GitHub skills

Avoid maintaining every external repository as a Git submodule unless there is a concrete reason to pin or modify the repository directly.

Source of Truth

The dotfiles repository should remain the source of truth.

The important distinction is:

dotfiles
    |
    | declares what skills I want
    v
skill manager / npx
    |
    | installs or updates
    v
canonical skill directory
    |
    +---- OpenCode
    |
    +---- Copilot CLI
    |
    +---- future agents

Do not make OpenCode or Copilot CLI the owner of the skill collection.

They are consumers of the same skills.

Desired Commands

Create a small CLI/script for managing the system.

The exact implementation is flexible, but the desired UX is approximately:

ai skills list
ai skills install
ai skills update
ai skills status

Or, if a simpler existing script convention fits the dotfiles better:

ai-skills list
ai-skills install
ai-skills update
ai-skills status

The implementation should remain simple.

Do not build a complicated package manager.

install

A fresh machine should be able to run something like:

ai skills install

and get all required skills.

It should:

Create required directories.

Install declared third-party skills.

Make personal skills available.

Create/update agent symlinks.

Be safe to run multiple times.

The operation should be idempotent.

Running it twice should not duplicate or corrupt anything.

update

The desired workflow is:

ai skills update

This should update external skills according to the declared configuration.

Personal skills should NOT be overwritten.

For example:

external/
    superpowers     <- can be updated
    ponytail        <- can be updated

personal/
    my-skill        <- never overwritten by external updater

list

Provide a simple view such as:

Personal:
  ✓ caveman
  ✓ go-review

External:
  ✓ superpowers
  ✓ ponytail
  ! some-skill (update available)

The exact output format is not important.

It should be easy to understand from a terminal.

Version / Locking

Investigate how the chosen npx skills tooling handles versions and reproducibility.

Do NOT blindly install the latest version every time.

Determine whether the ecosystem supports:

exact versions

Git commit pinning

tags

lock files

source repository tracking

Prefer a reproducible setup.

If the installer already provides a suitable lock mechanism, use it instead of creating a custom one.

If it does not, create the smallest possible metadata file needed to preserve reproducibility.

Example concept:

external:
  - source: github.com/...
    version: ...

The exact format should follow the actual tooling rather than inventing unnecessary abstractions.

Agent Integration

Keep one canonical skill location.

For example:

~/dotfiles/ai/skills/

Then expose it to agents through symlinks or whatever mechanism each agent officially supports.

Conceptually:

                 ┌── OpenCode
                 │
~/dotfiles/ai/skills
                 │
                 ├── Copilot CLI
                 │
                 └── future agents

Avoid maintaining separate copies of the same skill for every agent.

The same skill should not need to be cloned once for OpenCode and again for Copilot CLI.

Symlink Requirements

The setup should be safe if:

the target already exists

the symlink already exists

the target is missing

the dotfiles repository is moved

the setup is run repeatedly

Do not blindly delete arbitrary existing directories.

If an existing path is not owned by this setup, detect it and report the conflict.

Migration From Current Setup

Before changing anything:

Inspect the existing dotfiles structure.

Identify all current skills.

Identify which are:

personal

external

Git submodules

manually cloned repositories

Identify existing agent symlinks.

Identify existing management scripts.

Do not delete anything until the migration mapping is understood.

Create a migration mapping such as:

old location                new ownership
------------------------------------------------
skills/superpowers          external
skills/ponytail             external
skills/my-skill             personal
skills/foo                  external

For every existing external skill, determine its upstream repository before replacing it.

Important: Preserve Local Changes

Before migrating an external skill, check whether it contains local modifications.

For example:

git status
git diff

If an external repository has local changes, do NOT silently overwrite them.

Report them and let the user decide whether to:

discard them

preserve them

fork the skill

convert it into a personal skill

This is especially important because some existing skills may have been customized locally.

Git Submodules

Do not automatically remove all submodules.

For each skill currently represented as a submodule, determine whether it should become:

External dependency

Use the new skill installer if:

I do not modify the upstream source

I only consume the skill

normal upstream updates are desired

Personal/forked skill

Keep it Git-controlled if:

I modify it significantly

I maintain custom changes

I need exact Git history

I need a fork

Only remove a submodule after confirming that its contents are safely represented by the new system.

Backward Compatibility

Do not break existing agent configuration unnecessarily.

The migration should preserve the ability to use:

OpenCode

Copilot CLI

If existing configuration already works, modify only what is necessary.

Design Principles

1. Dotfiles remain authoritative

The repository should describe my desired environment.

2. Personal code is Git-native

My own skills should not depend on an external package manager.

3. External dependencies should use existing tooling

Do not reinvent:

clone
pull
checkout
update
version tracking

if the skills ecosystem already handles these correctly.

4. One canonical copy

Avoid:

OpenCode skills/
Copilot skills/
another-agent skills/

containing independent copies.

Prefer one canonical collection with adapters/symlinks.

5. Simple CLI

This is dotfiles infrastructure, not a new software product.

Prefer shell scripts and existing tools unless the complexity genuinely requires something else.

6. Reproducibility over convenience

A fresh machine should be able to recreate the environment.

7. Safe updates

Never silently overwrite personal work.

Implementation Steps

Phase 1 — Audit

Inspect the existing implementation.

Find:

current skill directory

Git submodules

clone scripts

update scripts

listing scripts

OpenCode configuration

Copilot CLI configuration

symlinks

local modifications

Do not change anything yet.

Phase 2 — Research the installed skills tooling

Determine the actual behavior of the npx skills tooling available on the system.

Verify:

installation location

update behavior

multi-agent support

version pinning

lock files

GitHub repository support

handling of local skills

whether symlinks are supported/required

whether it conflicts with the current dotfiles layout

Do not assume the tool works a certain way based only on its name.

Phase 3 — Design the migration

Based on the audit and actual tool behavior, choose the smallest architecture that satisfies the goals above.

Document the final structure before deleting/moving existing files.

Phase 4 — Migrate

Move personal skills into the Git-controlled personal directory.

Migrate external skills to the new installer.

Remove obsolete submodules/scripts only after verifying their replacements.

Phase 5 — Agent integration

Configure:

OpenCode
Copilot CLI

to consume the canonical skill collection.

Verify that both agents can discover and use the same skills.

Phase 6 — Reproducibility test

Simulate a fresh installation.

Verify:

ai skills install

from a clean environment produces the expected result.

Phase 7 — Cleanup

Only after successful verification:

remove obsolete scripts

remove unnecessary submodules

remove duplicate skill copies

update dotfiles documentation

commit the migration

Acceptance Criteria

The migration is complete when:

Personal skills are normal Git-tracked files.

External skills are managed without unnecessary Git submodules.

Dotfiles declare the desired skill set.

Skills can be installed on a new machine.

Skills can be updated with one command.

OpenCode can access the skills.

Copilot CLI can access the skills.

Existing local modifications are not silently lost.

Re-running installation is safe.

External skill versions are sufficiently reproducible.

No unnecessary duplicate copies exist.

Old management code is removed only after migration succeeds.

Documentation explains how to add a new personal skill.

Documentation explains how to add a new external skill.

Non-Goals

Do NOT:

build a full package manager

rewrite all agent configuration

automatically modify unrelated dotfiles

replace working agent configuration without reason

force every skill to use the same update mechanism

turn personal skills into external packages unnecessarily

optimize for maximum abstraction

Keep the implementation boring, predictable, and easy to debug.map <leader>/ <Plug>Commentary
