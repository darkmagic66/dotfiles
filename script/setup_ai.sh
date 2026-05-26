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

    # Link everything from your dotfiles into OpenCode and Gemini
    for item in "$AI_DOTFILES/$component"/*; do
        if [ -e "$item" ]; then
            base_name=$(basename "$item")
            ln -sf "$item" "$OPENCODE_DIR/$component/$base_name"
            
            # For Gemini, skills go into extensions/ for auto-discovery
            if [ "$component" == "skills" ]; then
                mkdir -p "$GEMINI_DIR/extensions"
                ln -sf "$item" "$GEMINI_DIR/extensions/$base_name"
            else
                ln -sf "$item" "$GEMINI_DIR/$component/$base_name"
            fi
        fi
    done
done

# Create extension-enablement.json for Gemini
if [ -d "$AI_DOTFILES/skills" ]; then
    ENABLEMENT_FILE="$GEMINI_DIR/extensions/extension-enablement.json"
    echo "{" > "$ENABLEMENT_FILE"
    first=true
    for skill in "$AI_DOTFILES/skills"/*; do
        if [ -d "$skill" ]; then
            # Only enable folders that look like valid extensions
            if [ -f "$skill/gemini-extension.json" ] || [ -f "$skill/GEMINI.md" ]; then
                skill_name=$(basename "$skill")
                if [ "$first" = true ]; then
                    first=false
                else
                    echo "," >> "$ENABLEMENT_FILE"
                fi
                echo "  \"$skill_name\": { \"overrides\": [\"$HOME/*\"] }" >> "$ENABLEMENT_FILE"
            fi
        fi
    done
    echo "" >> "$ENABLEMENT_FILE"
    echo "}" >> "$ENABLEMENT_FILE"
fi

# Link global AI configuration file
if [ -f "$AI_DOTFILES/GEMINI.md" ]; then
    ln -sf "$AI_DOTFILES/GEMINI.md" "$GEMINI_DIR/GEMINI.md"
fi

if [ -f "$AI_DOTFILES/gemini-settings.json" ]; then
    ln -sf "$AI_DOTFILES/gemini-settings.json" "$GEMINI_DIR/settings.json"
fi

if [ -f "$AI_DOTFILES/trustedFolders.json" ]; then
    ln -sf "$AI_DOTFILES/trustedFolders.json" "$GEMINI_DIR/trustedFolders.json"
fi

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