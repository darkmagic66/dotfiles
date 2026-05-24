#!/bin/bash

# Programs to install via apt
progs=(
    build-essential
    python3
)

# Installation commands via curl
echo "Installing core programming tools..."
curl -s "https://get.sdkman.io" | bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Download tools via wget
mkdir -p "$HOME/.local/bin"
wget "https://github.com/srevinsaju/zap/releases/download/continuous/zap-amd64" -O "$HOME/.local/bin/zap"
chmod +x "$HOME/.local/bin/zap"

# Install apt packages
for prog in "${progs[@]}"; do
    sudo apt install -y "$prog"
done

echo "Programming environment setup complete."
