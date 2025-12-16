#!/usr/bin/env bash
set -euo pipefail

# Configuration
REPO="godotjs/GodotJS"
FILE_PATTERN="linux-editor-4.5-v8.zip" # This might change if Godot version bumps

echo "Fetching latest release from GitHub..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/$REPO/releases" | jq -r '.[0].tag_name')

if [[ "$LATEST_TAG" == "null" || -z "$LATEST_TAG" ]]; then
    echo "Error: Could not find latest tag."
    exit 1
fi

echo "Latest version: $LATEST_TAG"

# Get current version from flake.nix
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' flake.nix | head -1)
echo "Current version: $CURRENT_VERSION"

if [[ "$CURRENT_VERSION" == "$LATEST_TAG" ]]; then
    echo "Already up to date."
    exit 0
fi

echo "New version found! Updating..."

# Calculate Hash
URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$FILE_PATTERN"
echo "Prefetching URL: $URL"
NEW_HASH=$(nix-prefetch-url --type sha256 "$URL")
SRI_HASH=$(nix hash to-sri --type sha256 "$NEW_HASH")

echo "New Hash: $SRI_HASH"

# Update Files
sed -i "s/version = \".*\"/version = \"$LATEST_TAG\"/" flake.nix
sed -i "s/version = \".*\"/version = \"$LATEST_TAG\"/" package.nix
sed -i "s|sha256 = \".*\"|sha256 = \"$SRI_HASH\"|" package.nix

echo "Testing build..."
if nix build .#default --no-link; then
    echo "Build successful!"

    # Commit if inside git
    if [ -d .git ]; then
        git config user.name "github-actions[bot]"
        git config user.email "github-actions[bot]@users.noreply.github.com"
        git add flake.nix package.nix
        git commit -m "chore: update GodotJS to $LATEST_TAG"
    fi
else
    echo "Build failed. Reverting changes..."
    git checkout flake.nix package.nix
    exit 1
fi
