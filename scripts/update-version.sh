#!/usr/bin/env bash
set -euo pipefail

# Configuration
REPO="godotjs/GodotJS"
# We look for a file that starts with 'linux-editor', contains 'v8', and ends with '.zip'
# This avoids hardcoding '4.5' or '4.5.1'
ASSET_REGEX="linux-editor-.*-v8.zip"

echo "Fetching latest release from GitHub..."
# Get the full JSON response first
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases?per_page=1" | jq '.[0]')
LATEST_TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name')

if [[ "$LATEST_TAG" == "null" || -z "$LATEST_TAG" ]]; then
    echo "Error: Could not find latest tag."
    exit 1
fi

echo "Latest version: $LATEST_TAG"

# --- NEW: Dynamic File Detection ---
# Parse the assets list to find the one matching our regex
FILE_NAME=$(echo "$RELEASE_JSON" | jq -r --arg regex "$ASSET_REGEX" '.assets[] | select(.name | test($regex)) | .name' | head -n 1)

if [[ -z "$FILE_NAME" ]]; then
    echo "Error: Could not find an asset matching pattern '$ASSET_REGEX'"
    exit 1
fi

echo "Found target asset: $FILE_NAME"
# -----------------------------------

# Get current version from flake.nix
CURRENT_VERSION=$(grep -oP 'version = "\K[^"]+' flake.nix | head -1)
echo "Current version: $CURRENT_VERSION"

if [[ "$CURRENT_VERSION" == "$LATEST_TAG" ]]; then
    echo "Already up to date."
    exit 0
fi

echo "New version found! Updating..."

# Calculate Hash
URL="https://github.com/$REPO/releases/download/$LATEST_TAG/$FILE_NAME"
echo "Prefetching URL: $URL"
NEW_HASH=$(nix-prefetch-url --type sha256 "$URL")
SRI_HASH=$(nix hash to-sri --type sha256 "$NEW_HASH")

echo "New Hash: $SRI_HASH"

# Update Files
sed -i "s/version = \".*\"/version = \"$LATEST_TAG\"/" flake.nix
sed -i "s/version = \".*\"/version = \"$LATEST_TAG\"/" package.nix
sed -i "s|sha256 = \".*\"|sha256 = \"$SRI_HASH\"|" package.nix

# Note: If your package.nix relies on the filename (e.g. for unpacking),
# you might need to update that too.
# For example, if package.nix has `src = fetchurl { url = ...; }` relying on version interpolation,
# ensure the naming convention in package.nix matches the new file.

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
