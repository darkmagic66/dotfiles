# justfile — thin wrapper around ./bootstrap
# Run `just` to list, `just install` for full setup, `just update` for re-sync.

set shell := ["bash", "-c"]

default:
    @just --list

# full setup: packages + config + ai (+ zsh/fonts/toolchains/mac defaults)
install:
    ./bootstrap

# dotfiles setup only (symlinks, no package installs)
config:
    ./bootstrap config

# packages only: manifest.yaml -> per-OS adapter
packages:
    ./bootstrap packages

# AI layer: skills + rtk plugin + graphify
ai:
    ./bootstrap ai

# fast re-sync: refresh zsh plugins + skill submodules, skips heavy stages
update:
    ./bootstrap --update

# skills management (submodule-backed)
skills-list:
    ./bootstrap ai list
skills-update:
    ./bootstrap ai update
skills-status:
    ./bootstrap ai status

# what applies to this machine (no changes made)
list:
    ./bootstrap list

# full-flow plan without executing anything
plan:
    PKG_DRY_RUN=1 ./bootstrap

# git pull + submodule update before running anything
sync:
    git pull --ff-only
    git submodule update --init --recursive

# update repo then re-sync everything
upgrade: sync update

# run everything fresh from a clone: sync + install
all: sync install
