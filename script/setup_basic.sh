#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# PKG_MODE selects what the adapter does: install (default — install missing +
# upgrade outdated), missing (install absent names only), upgrade (whole-system
# package upgrade). Flags below override the env; `bootstrap upgrade` sets it.
PKG_MODE="${PKG_MODE:-install}"

while [ $# -gt 0 ]; do
  case "$1" in
    --missing) PKG_MODE="missing" ;;
    --upgrade) PKG_MODE="upgrade" ;;
    *)
      echo "Usage: ./setup_basic.sh [--missing|--upgrade]   (or set \$DISTRO=mac|debian|arch|cachyos|fedora)" >&2
      exit 1
      ;;
  esac
  shift
done
export PKG_MODE

# DISTRO is normally exported by install.sh; fall back to local detect when
# run standalone.
if [ -z "${DISTRO:-}" ]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
  elif [ "$(uname)" == "Darwin" ]; then
    DISTRO="mac"
  else
    echo "Usage: ./setup_basic.sh   (or set \$DISTRO=mac|debian|arch|cachyos|fedora)"
    exit 1
  fi
fi

# Shared libs provide DOTFILES_DIR, log/warn/die, manifest_packages. They also
# run their own OS detect (which would overwrite DISTRO above) — remember the
# resolved value and restore it after sourcing so the env/standalone detect wins.
_PRESET_DISTRO="${DISTRO:-}"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../bootstrap.d/lib/common.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../bootstrap.d/lib/manifest.sh"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../bootstrap.d/lib/hosts.sh"
DISTRO="${_PRESET_DISTRO}"
export DISTRO

# Resolve ROLE before any adapter runs; brew's role gating depends on it.
# A pre-set ROLE env is honored by resolve_role (skips prompt/table lookup).
resolve_role

# --- Package adapters (self-guarded) ------------------------------------------
# Packages live in packages/manifest.yaml; per-OS adapters live in
# bootstrap.d/lib/adapters/<os>.sh and define run_<distro>_install. Each adapter
# is a no-op when sourced for another distro, so the glob is safe to source
# unconditionally.
for f in "${DOTFILES_DIR}"/bootstrap.d/lib/adapters/*.sh; do
  [ -f "$f" ] || continue
  # shellcheck disable=SC1090
  source "$f"
done

# --- Dispatch ------------------------------------------------------------------
# Resolve the adapter key from DISTRO, then pick install vs upgrade by PKG_MODE.
case "$DISTRO" in
  arch|cachyos|archlabs|endeavouros|manjaro)
    _adapter_key="arch"
    ;;
  debian|pop|ubuntu)
    _adapter_key="debian"
    ;;
  fedora)
    _adapter_key="fedora"
    ;;
  mac)
    _adapter_key="mac"
    ;;
  windows)
    _adapter_key="windows"
    ;;
  *)
    echo "Unsupported OS/Distro: $DISTRO"
    exit 1
    ;;
esac

if [ "$PKG_MODE" == "upgrade" ]; then
  "run_${_adapter_key}_upgrade"
else
  "run_${_adapter_key}_install"
fi

if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
  log "[dry-run] base package plan complete; nothing was installed"
elif [ "$PKG_MODE" == "upgrade" ]; then
  echo "Packages upgraded successfully."
elif [ "$PKG_MODE" == "missing" ]; then
  echo "Missing packages installed successfully."
else
  echo "Base packages installed successfully."
fi
