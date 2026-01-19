#!/bin/bash
set -e

AGENTIC_DIR="$HOME/devel/agentic"
AGENTIC_REPO="git@github.com:michaldziurowski/agentic.git"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"

# Clone agentic repo if not present
if [ ! -d "$AGENTIC_DIR" ]; then
    echo "Cloning agentic repository..."
    git clone "$AGENTIC_REPO" "$AGENTIC_DIR"
else
    echo "Agentic repository already exists"
fi

mkdir -p "$SKILLS_DIR"

# Link CLAUDE.md
ln -sf "$AGENTIC_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
echo "Linked: CLAUDE.md"

# Link settings.json
ln -sf "$AGENTIC_DIR/settings.json" "$CLAUDE_DIR/settings.json"
echo "Linked: settings.json"

# Link each skill directory
for skill in "$AGENTIC_DIR/skills"/*/; do
    skill_name=$(basename "$skill")
    [[ "$skill_name" == .* ]] && continue
    ln -sf "$skill" "$SKILLS_DIR/$skill_name"
    echo "Linked skill: $skill_name"
done
