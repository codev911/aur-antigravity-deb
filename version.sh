#!/bin/bash
# Find version information to fill in PKGBUILD
# This is a quick check script - use update.sh for full PKGBUILD generation

REPO_URL="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"

echo "=== x86_64 version information ==="
curl -fsSL "${REPO_URL}/dists/antigravity-debian/main/binary-amd64/Packages" | grep -E "^(Package|Version|MD5sum):" | tail -2

echo ""
echo "=== aarch64 version information ==="
curl -fsSL "${REPO_URL}/dists/antigravity-debian/main/binary-arm64/Packages" | grep -E "^(Package|Version|MD5sum):" | tail -2
