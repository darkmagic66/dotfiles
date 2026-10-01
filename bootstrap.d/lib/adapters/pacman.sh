#!/usr/bin/env bash
# bootstrap.d/lib/adapters/pacman.sh — Arch-family package adapter.
# Applies to: arch cachyos archlabs endeavouros manjaro
# Sourced by setup_basic.sh (and other callers that source the lib dir first);
# sources nothing itself — the caller must provide log/warn/die and
# manifest_packages (bootstrap.d/lib/common.sh + manifest.sh). Self-guard:
# no-op (defines nothing) when sourced for another distro.
# Platform steps moved verbatim from the old script/setup_os/arch.sh.
# PKG_DRY_RUN=1 is an env (not a flag): print the commands that would run,
# execute nothing.

case "${DISTRO:-}" in
  arch|cachyos|archlabs|endeavouros|manjaro) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

run_arch_install() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi

  # --- Base packages: manifest common + linux → pacman ------------------------
  # Repo names go through plain pacman. Anything outside the configured repos
  # (probed read-only with `pacman -Si`, e.g. brave-bin on AUR) is collected
  # and routed through the AUR helper loop below.
  local group group_names name
  local names=""
  local aur_names=""
  for group in common linux; do
    group_names="$(manifest_packages "$group")" \
      || die "manifest: cannot resolve package group '$group'; no packages installed"
    for name in $group_names; do
      if (( dry_run )); then
        # Dry-run: app-level heuristic only (no repo probing) so the printed
        # plan stays fully offline.
        case "$name" in
          *-bin|*-git) aur_names+="${aur_names:+ }${name}" ;;
          *)           names+="${names:+ }${name}" ;;
        esac
      elif pacman -Si "$name" >/dev/null 2>&1; then
        names+="${names:+ }${name}"
      else
        aur_names+="${aur_names:+ }${name}"
      fi
    done
  done

  if (( dry_run )); then
    log "[dry-run] sudo pacman -S --needed --noconfirm $names"
  else
    # shellcheck disable=SC2086  # word-split manifest names on purpose
    sudo pacman -S --needed --noconfirm $names
  fi

  # --- AUR helper ------------------------------------------------------------
  # Anything manifest-true AUR (probed in the base pass: e.g. brave-bin) plus
  # the fixed-only steps below. CachyOS ships paru in the [cachyos] repo;
  # plain Arch doesn't.
  if [ -n "$aur_names" ]; then
    if (( dry_run )); then
      log "[dry-run] AUR install (paru/yay, --needed --noconfirm): $aur_names"
    elif command -v paru >/dev/null 2>&1; then
      # shellcheck disable=SC2086  # word-split on purpose
      paru -S --needed --noconfirm $aur_names
    elif command -v yay >/dev/null 2>&1; then
      # shellcheck disable=SC2086  # word-split on purpose
      yay -S --needed --noconfirm $aur_names
    else
      echo "Warning: no AUR helper (yay/paru) found. Installing 'paru' first..."
      if sudo pacman -S --needed --noconfirm paru 2>/dev/null; then
        # shellcheck disable=SC2086  # word-split on purpose
        paru -S --needed --noconfirm $aur_names
      else
        echo "Warning: could not install an AUR helper. Install manually: yay -S $aur_names"
      fi
    fi
  fi

  # --- AUR helper ------------------------------------------------------------
  # VS Code (visual-studio-code-bin, MS binary) is the only package that needs
  # an AUR helper. CachyOS ships paru in the [cachyos] repo; plain Arch doesn't.
  if (( dry_run )); then
    if command -v yay >/dev/null 2>&1 || command -v paru >/dev/null 2>&1; then
      log "[dry-run] AUR helper already present; no bootstrap step"
    else
      log "[dry-run] sudo pacman -S --needed --noconfirm paru  (cachyos [cachyos] repo) || base-devel + git + makepkg yay build from AUR"
    fi
  elif ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
    if sudo pacman -S --needed --noconfirm paru 2>/dev/null; then
      echo "paru installed from [cachyos] repo."
    else
      echo "Building yay from AUR..."
      sudo pacman -S --needed --noconfirm base-devel git
      tmpdir="$(mktemp -d)"
      trap 'rm -rf "$tmpdir"' EXIT
      git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
      ( cd "$tmpdir/yay" && makepkg -si --noconfirm )
    fi
  fi

  # --- VS Code (MS binary, AUR) ----------------------------------------------
  if (( dry_run )); then
    if command -v paru >/dev/null 2>&1; then
      log "[dry-run] paru -S --needed --noconfirm visual-studio-code-bin"
    elif command -v yay >/dev/null 2>&1; then
      log "[dry-run] yay -S --needed --noconfirm visual-studio-code-bin"
    else
      log "[dry-run] no AUR helper found; manual install needed: yay -S visual-studio-code-bin"
    fi
  else
    echo "Installing Visual Studio Code..."
    if command -v paru >/dev/null 2>&1; then
      paru -S --needed --noconfirm visual-studio-code-bin
    elif command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm visual-studio-code-bin
    else
      echo "Warning: no AUR helper (yay/paru) found. Install manually: yay -S visual-studio-code-bin"
    fi
  fi

  # --- xxh (portable shell over ssh, AUR) --------------------------------------
  # NOTE: xxh-git AUR pkg is broken — its PKGBUILD calls setup.py which upstream
  # removed. python-xxh builds correctly via python-build (PEP 517), but its
  # makedepends miss python-setuptools (--no-isolation needs the build backend
  # in system python), so it's installed explicitly above.
  if (( dry_run )); then
    log "[dry-run] check python-setuptools (pacman -Q) and install when missing"
    if command -v paru >/dev/null 2>&1; then
      log "[dry-run] paru -S --needed --noconfirm python-xxh"
    elif command -v yay >/dev/null 2>&1; then
      log "[dry-run] yay -S --needed --noconfirm python-xxh"
    else
      log "[dry-run] no AUR helper found; manual install needed: yay -S python-xxh"
    fi
  else
    if ! pacman -Q python-setuptools >/dev/null 2>&1; then
      sudo pacman -S --needed --noconfirm python-setuptools
    fi
    if command -v paru >/dev/null 2>&1; then
      paru -S --needed --noconfirm python-xxh
    elif command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm python-xxh
    else
      echo "Warning: no AUR helper (yay/paru) found. Install manually: yay -S python-xxh"
    fi
  fi

  # --- Enable system services for Hyprland session (best-effort) -------------
  if (( dry_run )); then
    log "[dry-run] sudo systemctl enable --now NetworkManager bluetooth cups fstrim.timer udisks2"
    log "[dry-run] sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer  (only when those timers exist)"
  else
    echo "Enabling system services..."
    sudo systemctl enable --now \
      NetworkManager bluetooth cups fstrim.timer udisks2 2>/dev/null || true
    if systemctl list-unit-files snapper-timeline.timer >/dev/null 2>&1; then
      sudo systemctl enable --now \
        snapper-timeline.timer snapper-cleanup.timer 2>/dev/null || true
    fi
  fi

  # --- CachyOS mirror rater -------------------------------------------------
  if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
    if (( dry_run )); then
      log "[dry-run] sudo cachyos-rate-mirrors"
    else
      sudo cachyos-rate-mirrors 2>/dev/null || true
    fi
  fi

  # --- Optional Hyprland GUI extras (NOT installed by default) --------------
  # Uncomment the line below to install when you want them:
  #   paru -S --needed waypaper nwg-look nwg-displays gtk4-layer-shell
  #
  # tree-sitter-cli is also available via pacman from extra:
  #   sudo pacman -S --needed tree-sitter-cli
}
