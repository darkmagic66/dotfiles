#!/usr/bin/env bash
# bootstrap.d/lib/adapters/debian.sh — Debian/Ubuntu-family package adapter.
# Applies to: debian pop ubuntu
# Sourced by setup_basic.sh (and other callers that source the lib dir first);
# sources nothing itself — the caller must provide log/warn/die and
# manifest_packages (bootstrap.d/lib/common.sh + manifest.sh). Self-guard:
# no-op (defines nothing) when sourced for another distro.
# Content moved verbatim from the old script/setup_basic.sh install_debian
# body (eza upstream deb repo) and the old script/setup_os/debian.sh (fd
# symlink, zed installer, vscode MS apt repo). Base packages come from the
# manifest `common` group; OS-specific base deps (tldr asciinema python3
# build-essential) stay hardcoded here — not manifest material (spec G2).
# PKG_DRY_RUN=1 is an env (not a flag): print the commands that would run,
# execute nothing.

case "${DISTRO:-}" in
  debian|pop|ubuntu) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

run_debian_install() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi

  # --- Base packages: manifest common → apt -----------------------------------
  # Minimal name mapping: `fd` is named fd-find on Debian; the conventional
  # `fd` symlink is created post-install below. `just` is named `rust-just`
  # on Debian/Ubuntu (the binary is still `just`). All other common names are
  # valid apt package names as-is.
  local group group_names name
  group_names="$(manifest_packages common)" \
    || die "manifest: cannot resolve package group 'common'; no packages installed"
  local names=""
  for name in $group_names; do
    [ "$name" = "fd" ] && name="fd-find"
    [ "$name" = "just" ] && name="rust-just"
    names+="${names:+ }${name}"
  done
  # Debian-specific base deps (kept hardcoded, spec G2)
  names+=" tldr asciinema python3 build-essential"

  if (( dry_run )); then
    log "[dry-run] sudo apt update"
  else
    sudo apt update
  fi

  # --- eza upstream deb repo ---------------------------------------------------
  # eza is not in older Debian/Ubuntu/Pop!_OS repos — install from the official
  # deb repo (also covers the eza entry from the manifest `common` group, which
  # lands in the apt packages list below either way).
  if (( dry_run )); then
    log "[dry-run] eza deb repo (only when 'eza' missing): register upstream deb repo (keyring import)"
    log "[dry-run] sudo mkdir -p /etc/apt/keyrings"
    log "[dry-run] sudo wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg"
    log "[dry-run] echo 'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main' | sudo tee /etc/apt/sources.list.d/gierens.list"
    log "[dry-run] sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list"
  elif ! command -v eza >/dev/null 2>&1; then
    echo "Installing eza from upstream deb repo..."
    sudo mkdir -p /etc/apt/keyrings
    sudo wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
      | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  fi

  if (( dry_run )); then
    log "[dry-run] sudo apt install -y$names"
  else
    # shellcheck disable=SC2086  # word-split manifest names on purpose
    sudo apt install -y $names
  fi

  # --- fd symlink (fd is named fd-find on Debian) -----------------------------
  if (( dry_run )); then
    log "[dry-run] fd symlink (when /usr/bin/fdfind exists and /usr/local/bin/fd does not): sudo ln -s /usr/bin/fdfind /usr/local/bin/fd"
  elif [ -f /usr/bin/fdfind ] && [ ! -f /usr/local/bin/fd ]; then
    echo "Linking /usr/local/bin/fd -> /usr/bin/fdfind ..."
    sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
  fi

  # --- Zed (official installer; not in Debian repos; ~/.local/bin/zed) --------
  if (( dry_run )); then
    log "[dry-run] zed (only when 'zed' missing): curl -f https://zed.dev/install.sh | sh   (installs zed to ~/.local/bin)"
  elif ! command -v zed >/dev/null 2>&1; then
    echo "Installing Zed..."
    curl -f https://zed.dev/install.sh | sh
  fi

  # --- Visual Studio Code (official MS binary via Microsoft apt repo) ----------
  # This `code` package is the MS binary with the proprietary marketplace;
  # distinct from the OSS `code` build some distros ship.
  if (( dry_run )); then
    log "[dry-run] vscode (only when 'code' missing): register Microsoft apt repo + install code:"
    log "[dry-run] sudo install -d -m 0755 /etc/apt/keyrings"
    log "[dry-run] wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg"
    log "[dry-run] sudo chmod 644 /etc/apt/keyrings/packages.microsoft.gpg"
    log "[dry-run] echo 'deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list"
    log "[dry-run] sudo apt update && sudo apt install -y code"
  elif ! command -v code >/dev/null 2>&1; then
    echo "Installing Visual Studio Code (MS apt repo)..."
    sudo install -d -m 0755 /etc/apt/keyrings
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
      | sudo gpg --dearmor -o /etc/apt/keyrings/packages.microsoft.gpg
    sudo chmod 644 /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo apt update
    sudo apt install -y code
  fi
}
