#!/bin/bash
# setup_os/fedora.sh — extras for Fedora.
# Applies to: fedora
# Sourced by setup_basic.sh. Self-guard: no-op when sourced for other distros.

case "${DISTRO:-}" in
  fedora) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

# Zed (official installer; not in Fedora repos). Installs to ~/.local/bin/zed.
if ! command -v zed >/dev/null 2>&1; then
  echo "Installing Zed..."
  curl -f https://zed.dev/install.sh | sh
fi

# Visual Studio Code (official MS binary via Microsoft dnf repo).
if ! command -v code >/dev/null 2>&1; then
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