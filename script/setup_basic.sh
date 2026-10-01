#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
case "$DISTRO" in
  arch|cachyos|archlabs|endeavouros|manjaro)
    run_arch_install
    ;;
  debian|pop|ubuntu)
    run_debian_install
    ;;
  fedora)
    run_fedora_install
    ;;
  mac)
    run_mac_install
    ;;
  windows)
    run_windows_install
    ;;
  *)
    echo "Unsupported OS/Distro: $DISTRO"
    exit 1
    ;;
esac

if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
  log "[dry-run] base package plan complete; nothing was installed"
else
  echo "Base packages installed successfully."
fi
