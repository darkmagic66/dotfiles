#!/bin/bash
# setup_os/debian.sh — extras for the Debian / Ubuntu family.
# Applies to: debian pop ubuntu
# Sourced by setup_basic.sh. Self-guard: no-op when sourced for other distros.

case "${DISTRO:-}" in
  debian|pop|ubuntu) ;;
  *)
    [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]] && exit 0 || return 0 ;;
esac

# fd is named fd-find on Debian — create the conventional `fd` symlink.
if [ -f /usr/bin/fdfind ] && [ ! -f /usr/local/bin/fd ]; then
  echo "Linking /usr/local/bin/fd -> /usr/bin/fdfind ..."
  sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
fi

# Zed (official installer; not in Debian repos).
# Installs to ~/.local/bin/zed.
if ! command -v zed >/dev/null 2>&1; then
  echo "Installing Zed..."
  curl -f https://zed.dev/install.sh | sh
fi

# Visual Studio Code (official MS binary via Microsoft apt repo).
# Note: this `code` package is the MS binary with the proprietary marketplace;
# it's distinct from the OSS `code` build that some distros ship.
if ! command -v code >/dev/null 2>&1; then
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