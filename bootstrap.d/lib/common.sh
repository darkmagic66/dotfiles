#!/usr/bin/env bash
# bootstrap.d/lib/common.sh — shared helpers: logging, DOTFILES_DIR, OS detection.
# Idempotent to source. After sourcing, DOTFILES_DIR is set (env override wins,
# else resolved script-relative) and _dotf_os_detect() has exported OS_TYPE/DISTRO.

[[ -n "${_DOTF_COMMON_SOURCED:-}" ]] && return 0
_DOTF_COMMON_SOURCED=1

# --- DOTFILES_DIR: prefer existing env, else resolve from this file's location
# (this file lives in <repo>/bootstrap.d/lib/, so two levels up is the repo root).
_DOTF_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname -- "$(dirname -- "$_DOTF_LIB_DIR")")}"
export DOTFILES_DIR

# --- log helpers: colored on the target stream being a tty, plain otherwise.
# NO_COLOR (https://no-color.org/) disables coloring entirely.
_dotf_on() { [[ -n "$1" ]] && [[ -t "$1" ]]; }

log() { # stdout, green
  if _dotf_on 1 && [[ -z "${NO_COLOR:-}" ]]; then printf '\033[32m%s\n\033[0m' "$*" >&1
  else printf '%s\n' "$*" >&1; fi
}

warn() { # stderr, yellow
  if _dotf_on 2 && [[ -z "${NO_COLOR:-}" ]]; then printf '\033[33m%s\n\033[0m' "$*" >&2
  else printf '%s\n' "$*" >&2; fi
}

die() { # stderr, red, exit 1
  if _dotf_on 2 && [[ -z "${NO_COLOR:-}" ]]; then printf '\033[31m%s\n\033[0m' "$*" >&2
  else printf '%s\n' "$*" >&2; fi
  exit 1
}

# --- OS detection; mirrors legacy install.sh:23-42 normalization verbatim:
# Darwin → mac; Linux → /etc/os-release ID, else debian if /etc/debian_version,
# else linux_unknown. Anything else is unsupported.
_dotf_os_detect() {
  OS_TYPE="$(uname)"
  DISTRO=""

  if [ "$OS_TYPE" == "Darwin" ]; then
    DISTRO="mac"
  elif [ "$OS_TYPE" == "Linux" ]; then
    if [ -r /etc/os-release ]; then
      DISTRO="$(. /etc/os-release && printf '%s' "${ID:-}")"
    fi
    if [ -z "$DISTRO" ] && [ -f /etc/debian_version ]; then
      DISTRO="debian"
    fi
    if [ -z "$DISTRO" ]; then
      DISTRO="linux_unknown"
    fi
  else
    die "Unsupported OS: $OS_TYPE"
  fi

  export OS_TYPE DISTRO
}

_dotf_os_detect
