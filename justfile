# justfile — thin wrapper around ./bootstrap
# Run `just` to list, `just install` for full setup, `just update` for re-sync,
# `just upgrade` for system package upgrades.

set shell := ["bash", "-c"]

default:
    @just --list

# full setup: packages + config + ai (+ zsh/fonts/toolchains/mac defaults)
install:
    ./bootstrap

# dotfiles setup only (symlinks, no package installs)
config:
    ./bootstrap config

# packages only: manifest.yaml -> per-OS adapter (installs missing, upgrades outdated)
packages:
    ./bootstrap packages

# packages only, missing-only: install absent names, never upgrade (no app restarts)
packages-missing:
    ./bootstrap packages --missing

# upgrade all: refresh the dotfiles repo + whole-system package upgrade
upgrade:
    ./bootstrap upgrade

# AI layer: skills + rtk plugin + graphify + ocr
ai:
    ./bootstrap ai

# fast dotfiles re-sync: repo pull + submodules, refresh zsh plugins + skill submodules
update:
    git pull --ff-only
    git submodule update --init --recursive
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

# run everything fresh from a clone: sync + install
all: sync install
