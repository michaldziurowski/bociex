#!/bin/bash
set -e

# Ensure stow is installed
sudo pacman -S --noconfirm --needed stow

AGENTIC_DIR="$HOME/devel/agentic"
AGENTIC_REPO="git@github.com:michaldziurowski/agentic.git"
CLAUDE_DIR="$HOME/.claude"

# Clone agentic repo if not present
if [ ! -d "$AGENTIC_DIR" ]; then
    echo "Cloning agentic repository..."
    git clone "$AGENTIC_REPO" "$AGENTIC_DIR"
else
    echo "Agentic repository already exists"
fi

mkdir -p "$CLAUDE_DIR"
mkdir -p "$CLAUDE_DIR/skills"

# Use stow to link all files from agentic repo to claude dir
# --no-folding: create individual symlinks (preserves external skills like omarchy)
# --restow: makes operation idempotent - removes and recreates symlinks
# --ignore: skip hidden files/directories (.git, .gitignore, etc.)
stow --restow --no-folding --ignore='^\..*' -t "$CLAUDE_DIR" -d "$HOME/devel" agentic

echo "Stow complete"
