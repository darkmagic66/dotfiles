#!/usr/bin/env bash
# bootstrap.d/lib/adapters/fedora.sh — Fedora package adapter.
# Applies to: fedora
# Sourced by setup_basic.sh (and other callers that source the lib dir first);
# sources nothing itself — the caller must provide log/warn/die and
# manifest_packages (bootstrap.d/lib/common.sh + manifest.sh). Self-guard:
# no-op (defines nothing) when sourced for another distro.
# Content moved verbatim from the old script/setup_basic.sh install_fedora
# body and the old script/setup_os/fedora.sh (zed installer, vscode MS dnf
# repo). Base packages come from the manifest `common` group; OS-specific
# base deps (tldr asciinema) stay hardcoded here — not manifest material
# (spec G2). PKG_DRY_RUN=1 is an env (not a flag): print the commands that
# would run, execute nothing.

case "${DISTRO:-}" in
  fedora) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

run_fedora_install() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi

  # --- Base packages: manifest common → dnf -----------------------------------
  # Minimal name mapping: `just` is named `rust-just` on Fedora (the binary
  # is still `just`). `bun` has no Fedora package at all — it is skipped here
  # and installed from the official installer below. All other common names
  # are valid dnf package names.
  local group_names name
  group_names="$(manifest_packages common)" \
    || die "manifest: cannot resolve package group 'common'; no packages installed"
  local names=""
  for name in $group_names; do
    [ "$name" = "just" ] && name="rust-just"
    [ "$name" = "bun" ] && continue
    names+="${names:+ }${name}"
  done
  # Fedora-specific base deps (kept hardcoded, spec G2)
  names+=" tldr asciinema"

  # PKG_MODE=missing: `dnf install` upgrades in place; skip names already
  # installed so a missing-only run stays a no-op. Local probe (rpm db), no net.
  if [[ "${PKG_MODE:-install}" == "missing" ]]; then
    local keep=""
    for name in $names; do
      rpm -q "$name" >/dev/null 2>&1 && continue
      keep+="${keep:+ }${name}"
    done
    names="$keep"
  fi

  if (( dry_run )); then
    log "[dry-run] sudo dnf install -y$names"
  else
    # shellcheck disable=SC2086  # word-split manifest names on purpose
    sudo dnf install -y $names
  fi

  # --- bun (no Fedora package; official installer → ~/.bun) -------------------
  if (( dry_run )); then
    log "[dry-run] bun (only when 'bun' missing): curl -fsSL https://bun.sh/install | bash   (installs to ~/.bun)"
  elif ! command -v bun >/dev/null 2>&1; then
    echo "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
  fi

  # --- Zed (official installer; not in Fedora repos; ~/.local/bin/zed) --------
  if (( dry_run )); then
    log "[dry-run] zed (only when 'zed' missing): curl -f https://zed.dev/install.sh | sh   (installs zed to ~/.local/bin)"
  elif ! command -v zed >/dev/null 2>&1; then
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
  fi

  # --- Visual Studio Code (official MS binary via Microsoft dnf repo) ---------
  if (( dry_run )); then
    log "[dry-run] vscode (only when 'code' missing): register Microsoft dnf repo + install code:"
    log "[dry-run] sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc"
    log "[dry-run] write /etc/yum.repos.d/vscode.repo ([code] baseurl=packages.microsoft.com/yumrepos/vscode gpgcheck=1)"
    log "[dry-run] sudo dnf install -y code"
  elif ! command -v code >/dev/null 2>&1; then
    echo "Installing Visual Studio Code (MS dnf repo)..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat <<'EOF' | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo dnf install -y code
  fi
}

# --- upgrade: whole-system `dnf upgrade` (manifest-independent) --------------
# `bootstrap upgrade` lands here.
run_fedora_upgrade() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi

  if (( dry_run )); then
    log "[dry-run] sudo dnf upgrade -y   (whole system)"
    return 0
  fi

  echo "Upgrading system packages (dnf)..."
  sudo dnf upgrade -y
}
