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
