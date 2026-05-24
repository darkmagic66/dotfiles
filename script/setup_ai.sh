#!/usr/bin/env bash

# Define source and target directories
AI_DOTFILES="$HOME/dotfiles/ai-env"
OPENCODE_DIR="$HOME/.config/opencode"
GEMINI_DIR="$HOME/.gemini"

echo "Deploying AI Environment..."

# 1. Ensure base config directories exist
mkdir -p "$OPENCODE_DIR" "$GEMINI_DIR"

# 2. Array of the components you are managing
COMPONENTS=("agents" "instructions" "prompts" "skills" "tools")

# 3. Loop through and symlink each component folder
for component in "${COMPONENTS[@]}"; do
    # Create the target directories if they don't exist
    mkdir -p "$OPENCODE_DIR/$component"
    mkdir -p "$GEMINI_DIR/$component"

    # Link everything from your dotfiles into OpenCode
    # (Using find to link contents rather than the parent folder allows 
    # both tools to have their own default files alongside your dotfiles)
    for item in "$AI_DOTFILES/$component"/*; do
        if [ -e "$item" ]; then
            base_name=$(basename "$item")
            ln -sf "$item" "$OPENCODE_DIR/$component/$base_name"
            ln -sf "$item" "$GEMINI_DIR/$component/$base_name"
        fi
    done
done

# 4. Install AI Tools
echo "Installing AI Tools..."

# Install rtk
if ! command -v rtk &> /dev/null; then
    echo "Installing rtk..."
    curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
    # Initialize rtk for Gemini CLI
    if command -v rtk &> /dev/null; then
        rtk init -g --gemini
    fi
else
    echo "rtk is already installed."
    # Ensure it's initialized for Gemini CLI
    rtk init -g --gemini
fi

# Install GitNexus
if ! command -v gitnexus &> /dev/null; then
    echo "Installing GitNexus..."
    if command -v npm &> /dev/null; then
        npm install -g gitnexus
    else
        echo "npm not found, skipping GitNexus installation."
    fi
else
    echo "GitNexus is already installed."
fi

echo "AI Environment linked and tools installed successfully."