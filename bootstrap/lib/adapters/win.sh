#!/usr/bin/env bash
# bootstrap/lib/adapters/win.sh — Windows (winget) package adapter. SKETCH ONLY.
# Applies to: windows (OS_TYPE MINGW*/MSYS*; no real windows machine reachable
# yet, never executed in this project — documented limitation, spec G2).
# Sourced by setup_basic.sh (and other callers that source the lib dir first);
# sources nothing itself — the caller must provide log/warn/die and
# manifest_packages (bootstrap/lib/common.sh + manifest.sh). Self-guard:
# no-op (defines nothing) when sourced elsewhere.
# PKG_DRY_RUN=1 is an env (not a flag): print the commands that would run,
# execute nothing — which is all this adapter ever does anyway.

case "${DISTRO:-}" in
  windows) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

run_windows_install() {
  local dry_run=0
  if [[ "${PKG_DRY_RUN:-0}" == "1" ]]; then
    dry_run=1
  fi
  if (( dry_run )); then
    log "[dry-run] winget plan (sketch adapter — never executes)"
  fi

  # --- Tools: manifest windows → winget ids ------------------------------------
  local group_names pkg
  group_names="$(manifest_packages windows)" \
    || die "manifest: cannot resolve package group 'windows'; no packages installed"
  for pkg in $group_names; do
    if (( dry_run )); then
      log "[dry-run] winget install -e --id $pkg"
    else
      echo "Would run: winget install -e --id $pkg   (sketch adapter; not executed)"
    fi
  done

  if (( dry_run )); then
    log "[dry-run] windows sketch adapter complete; nothing was installed"
  fi
}
