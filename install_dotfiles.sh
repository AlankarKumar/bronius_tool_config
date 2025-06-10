#!/bin/bash

# Get the repo root directory (where this script is run)
REPO_DIR="$(pwd)"
CONFIG_DIR="$HOME/.config"

# List of config folders to copy
CONFIG_FOLDERS=("nvim" "tmux" "alacritty")

# Loop through each folder and copy to ~/.config
for folder in "${CONFIG_FOLDERS[@]}"; do
  SRC="$REPO_DIR/$folder"
  DEST="$CONFIG_DIR/$folder"

  if [ -d "$SRC" ]; then
    echo "📦 Copying $folder to $CONFIG_DIR"
    mkdir -p "$DEST"
    cp -r "$SRC/"* "$DEST/"
  else
    echo "⚠️  Skipping $folder — not found in repo"
  fi
done

echo "✅ All configs copied successfully."
