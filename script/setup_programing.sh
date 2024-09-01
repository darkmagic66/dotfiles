!#/bin/bash

progs=(
    build-essential  
    python3
)

curls=(
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
)

wgets(
    "https://github.com/srevinsaju/zap/releases/download/continuous/zap-amd64" 
)

for progs in "${progs[@]}"; do
    sudo apt install "$progs"
