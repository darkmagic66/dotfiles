#!/usr/bin/env bash
# bootstrap.d/lib/adapters/brew.sh — macOS (Homebrew) package adapter.
# Applies to: mac
# Sourced by setup_basic.sh (and other callers that source the lib dir first);
# sources nothing itself — the caller must provide log/warn/die and
# manifest_packages (bootstrap.d/lib/common.sh + manifest.sh). Self-guard:
# no-op (defines nothing) when sourced for another distro.
# Replaces the old script/setup_os/mac.sh `brew bundle` flow and the old
# install_mac bootstrap block. PKG_DRY_RUN=1 is an env (not a flag): print the
# commands that would run, execute nothing (brew's own --dry-run is not used;
# it is unreliable for casks).

case "${DISTRO:-}" in
  mac) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

run_mac_install() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi

  # --- Formulas: manifest common + macos_extra ---------------------------------
  # SKIP list (explicit, per spec G2 — NEVER install from manifest via brew):
  #   curl: macOS ships a system curl (/usr/bin/curl, SecureTransport-backed,
  #         CA certs from the OS keychain); brew's curl would shadow it and
  #         break TLS trust. Keep the system one.
  local skip_curl="curl"

  local group group_names name
  local names=""
  for group in common macos_extra; do
    group_names="$(manifest_packages "$group")" \
      || die "manifest: cannot resolve package group '$group'; no packages installed"
    for name in $group_names; do
      [ "$name" = "$skip_curl" ] && continue
      names+="${names:+ }${name}"
    done
  done

  # --- Casks: manifest macos_casks (+ role_personal when ROLE=personal) --------
  local casks=""
  local role_groups=""
  [[ "${ROLE:-}" == "personal" ]] && role_groups="role_personal"
  for group in macos_casks $role_groups; do
    # CORE group: real resolution failure must not silently skip the cask
    # install. ROLE groups stay tolerant (legitimately absent/empty by role).
    if [[ "$group" == "macos_casks" ]]; then
      group_names="$(manifest_packages "$group")" \
        || die "manifest: cannot resolve cask group '$group'; no packages installed"
    else
      group_names="$(manifest_packages "$group")" || true
    fi
    [ -z "$group_names" ] && continue
    for name in $group_names; do
      casks+="${casks:+ }${name}"
    done
  done

  local role_note=""
  if [[ "${ROLE:-}" == "personal" ]]; then
    role_note=" + role_personal"
  fi

  # --- Dry-run: plan only, no brew invocation ----------------------------------
  if (( dry_run )); then
    log "[dry-run] bootstrap-if-missing: brew (curl install script) when not present"
    log "[dry-run] eval \"\$(brew shellenv)\"  (/opt/homebrew, fallback /usr/local)"
    log "[dry-run] brew update"
    log "[dry-run] brew install${names:+ $names}   (formulas: common${role_note} + macos_extra)"
    log "[dry-run] brew install --cask${casks:+ $casks}   (casks: macos_casks${role_note})"
    return 0
  fi

  # --- Brew presence: install-if-missing ---------------------------------------
  if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # shellenv eval — exact block ported from the legacy install_mac
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  echo "Updating brew..."
  brew update

  # shellcheck disable=SC2086  # word-split manifest names on purpose
  brew install $names

  echo "Installing casks..."
  # shellcheck disable=SC2086  # word-split manifest names on purpose
  if [ -n "$casks" ]; then
    brew install --cask $casks
  fi
}
