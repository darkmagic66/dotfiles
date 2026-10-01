#!/usr/bin/env bash
# bootstrap.d/lib/hosts.sh — machine profile & role resolution.
# Single edit point: HOST_ROLE table. Placeholders for machines not yet run
# (fill real hostnames during first install there); the current machine uses
# its real hostname.
#
# Resolution order:
#   1. persisted machine-local file: ~/.config/dotfiles/role  (untracked)
#   2. HOST_ROLE table lookup by hostname
#   3. interactive prompt (once), answer persisted to ~/.config/dotfiles/role

if [[ -n "${_DOTF_COMMON_SOURCED:-}" ]]; then :; else
  . "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"
fi

# Machine-local persisted role file (untracked; machine-local state, not in Git).
_dotf_role_persist_file() { printf '%s\n' "${HOME}/.config/dotfiles/role"; }

# HOST_ROLE: single edit point. macbook-m3 / macbook-m5 / windows-pc rows are
# PLACEHOLDERS — replace with the real hostnames during each machine's first
# install. thinkpad row uses the real current hostname (verified machine).
# NOTE: plain case statement, NOT `declare -A` — macOS ships bash 3.2, which
# has no associative arrays (`declare -A` aborts the whole install there).
# Prints the role for a hostname, or nothing when unknown.
_host_role_for() {
  case "$1" in
    thinkpad-p14s) printf 'personal\n' ;;
    macbook-m3)    printf 'company\n' ;;
    macbook-m5)    printf 'personal\n' ;;
    windows-pc)    printf 'personal\n' ;;
  esac
}

_dotf_role_valid() {
  [[ "$1" == "personal" || "$1" == "company" ]]
}

# resolve_role → sets global ROLE=personal|company.
resolve_role() {
  local role_file
  role_file="$(_dotf_role_persist_file)"

  # 0. pre-set ROLE env is honored (skips prompt/table; caller knows the role)
  if [[ -n "${ROLE:-}" ]]; then
    if _dotf_role_valid "$ROLE"; then
      return 0
    fi
    warn "ignoring invalid ROLE env '$ROLE'"
  fi
  ROLE=""
  local role_file
  role_file="$(_dotf_role_persist_file)"

  # 1. persisted machine-local role file takes precedence
  if [[ -s "$role_file" ]]; then
    local saved
    saved="$(head -n 1 -- "$role_file" | tr -d '[:space:]')"
    if _dotf_role_valid "$saved"; then
      ROLE="$saved"
      return 0
    fi
    warn "ignoring invalid persisted role '$saved' in $role_file"
  fi

  # 2. table lookup
  local host table_role
  host="$(hostname)"
  table_role="$(_host_role_for "$host")"
  if [[ -n "$table_role" ]] && _dotf_role_valid "$table_role"; then
    ROLE="$table_role"
    return 0
  fi

  # 3. interactive prompt; no tty → fail loudly (avoid silently wrong role)
  if [[ ! -t 0 ]]; then
    die "unknown host '$host' and no persisted role; run interactively once to pick personal|company"
  fi

  local answer
  while :; do
    read -r -p "Role for host '$host' [personal/company]: " answer
    case "$answer" in
      personal|company)
        ROLE="$answer"
        mkdir -p -- "$(dirname -- "$role_file")"
        printf '%s\n' "$ROLE" >"$role_file"
        log "role '$ROLE' saved to $role_file"
        return 0
        ;;
      *)
        warn "invalid answer; enter 'personal' or 'company'"
        ;;
    esac
  done
}
