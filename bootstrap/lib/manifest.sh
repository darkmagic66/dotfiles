#!/usr/bin/env bash
# bootstrap/lib/manifest.sh — package manifest parser (awk-free, pure bash).
# Contract (see packages/manifest.yaml): flat top-level groups `^[a-z_]+:`,
# items are `  - <value>` (2 spaces, dash, space, value to end of line).
# Needs log/warn from common.sh; auto-sources it when not already loaded.

if [[ -n "${_DOTF_COMMON_SOURCED:-}" ]]; then :; else
  . "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/common.sh"
fi

# manifest_packages <group> — print the group's package names space-separated
# on ONE line, breathe: trailing comments after values are stripped
# (`role_company: []  # comment` therefore yields an EMPTY result with exit 0,
# not a missing-group error). Missing manifest file or unknown group is fatal:
# warns on stderr and returns nonzero.
manifest_packages() {
  local group="$1"
  local manifest="${MANIFEST:-"${DOTFILES_DIR}/packages/manifest.yaml"}"

  if [[ ! -f "$manifest" ]]; then
    warn "manifest_packages: manifest file not found: $manifest"
    return 1
  fi
  if [[ -z "$group" ]]; then
    warn "manifest_packages: no group name given"
    return 1
  fi

  local in_group=0 found=0
  local line header rest item out=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}" # tolerate CRLF
    # trim trailing whitespace (strip shortest all-space suffix)
    line="${line%"${line##*[![:space:]]}"}"

    case "$line" in
      '#'*) continue ;;            # pure comment line
      '') continue ;;              # blank line
    esac

    # group header: ^[a-z_]+: with optional trailing comment after the value
    if [[ "$line" =~ ^[a-z_]+: ]]; then
      header="${line%%:*}"
      in_group=0
      rest="${line#*:}"          # inline value, e.g. `role_company: []  # note`
      rest="${rest%%#*}"         # strip comment first
      rest="${rest//[[:space:]]/}" # drop whitespace around value
      if [[ "$header" == "$group" ]]; then
        in_group=1
        found=1
        if [[ -n "$rest" && "$rest" != "[]" ]]; then
          out+="${out:+ }${rest}"   # inline, non-empty-list value
        fi
      fi
      continue
    fi

    # item line: exactly "  - value" (2 spaces, dash, space) until EOL
    if [[ "$line" == "  - "* ]]; then
      if (( in_group )); then
        item="${line#'  - '}"
        item="${item%%#*}"                       # strip trailing comment
        item="${item%"${item##*[![:space:]]}"}"  # trim trailing whitespace
        if [[ -n "$item" ]]; then
          out+="${out:+ }${item}"
        fi
      fi
      continue
    fi

    # any other line: ignored (future-format guard)
  done <"$manifest"

  if (( ! found )); then
    warn "manifest_packages: group '$group' not found in $manifest"
    return 1
  fi

  printf '%s\n' "$out"
  return 0
}
