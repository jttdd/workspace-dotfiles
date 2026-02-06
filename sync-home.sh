#!/bin/bash
set -e

DEST="$(dirname "$0")/aliases"
mkdir -p "$DEST"

FILES=(
    common.fish
    ddog-libstreaming.fish
    ddog.fish
)

for f in "${FILES[@]}"; do
    cp -L ~/.aliases/"$f" "$DEST/"
done

echo "Copied ${FILES[*]} to $DEST"

# Update git aliases in .gitconfig-ext (preserve other sections)
SCRIPT_DIR="$(dirname "$0")"
GITCONFIG_EXT="$SCRIPT_DIR/.gitconfig-ext"

# Extract new aliases from ~/.gitconfig
NEW_ALIASES=$(awk '/^\[alias\]/{found=1} /^\[/ && found && !/^\[alias\]/{exit} found{print}' ~/.gitconfig)

# Build new file: before [alias] + new aliases + after [alias]
{
  awk '/^\[alias\]/{exit} {print}' "$GITCONFIG_EXT"
  echo "$NEW_ALIASES"
  awk '/^\[alias\]/{found=1; next} /^\[/ && found{found=0} !found && /^\[/{p=1} p{print}' "$GITCONFIG_EXT"
} > "$GITCONFIG_EXT.tmp" && mv "$GITCONFIG_EXT.tmp" "$GITCONFIG_EXT"

echo "Updated git aliases in $GITCONFIG_EXT"

# Copy ~/.claude/CLAUDE.md
mkdir -p "$SCRIPT_DIR/.claude"
cp -L ~/.claude/CLAUDE.md "$SCRIPT_DIR/.claude/"
echo "Copied ~/.claude/CLAUDE.md"
