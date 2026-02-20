#!/bin/bash
# Update script for antigravity-custom AUR package
# This script fetches the latest version and generates an updated PKGBUILD

set -euo pipefail

# Configuration
PKGNAME="antigravity-deb"
REPO_URL="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
WORKDIR="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fetch version info from repository
fetch_version_info() {
    log_info "Fetching version information..."

    local x86_info=$(curl -fsSL "${REPO_URL}/dists/antigravity-debian/main/binary-amd64/Packages" | grep -E "^(Package|Version|MD5sum):" | tail -2)
    local arm64_info=$(curl -fsSL "${REPO_URL}/dists/antigravity-debian/main/binary-arm64/Packages" | grep -E "^(Package|Version|MD5sum):" | tail -2)

    # Parse version (format: 1.16.5-1770081357)
    X86_VERSION=$(echo "$x86_info" | grep "Version:" | awk '{print $2}')
    ARM64_VERSION=$(echo "$arm64_info" | grep "Version:" | awk '{print $2}')

    # Extract version components
    X86_PKGVER=$(echo "$X86_VERSION" | cut -d'-' -f1)
    X86_MINOR=$(echo "$X86_VERSION" | cut -d'-' -f2)
    X86_CHECKSUM=$(echo "$x86_info" | grep "MD5sum:" | awk '{print $2}')

    ARM64_PKGVER=$(echo "$ARM64_VERSION" | cut -d'-' -f1)
    ARM64_MINOR=$(echo "$ARM64_VERSION" | cut -d'-' -f2)
    ARM64_CHECKSUM=$(echo "$arm64_info" | grep "MD5sum:" | awk '{print $2}')

    # Sanity check: versions should match
    if [[ "$X86_PKGVER" != "$ARM64_PKGVER" ]]; then
        log_error "Version mismatch: x86_64=$X86_PKGVER, aarch64=$ARM64_PKGVER"
        exit 1
    fi

    PKGVER="$X86_PKGVER"
    _x86minor="$X86_MINOR"
    _arm64minor="$ARM64_MINOR"
    _x86check="$X86_CHECKSUM"
    _arm64check="$ARM64_CHECKSUM"

    log_info "Latest version: ${PKGVER}"
    log_info "  x86_64: ${PKGVER}-${_x86minor} (${_x86check})"
    log_info "  aarch64: ${PKGVER}-${_arm64minor} (${_arm64check})"
}

# Download .deb files and calculate SHA256 checksums
calculate_checksums() {
    log_info "Downloading .deb files to calculate checksums..."

    local tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    # Download URLs (note: using 'antigravity' not '$PKGNAME' as the package name on Google's servers)
    local x86_url="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_${PKGVER}-${_x86minor}_amd64_${_x86check}.deb"
    local arm64_url="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_${PKGVER}-${_arm64minor}_arm64_${_arm64check}.deb"

    log_info "Downloading x86_64 package..."
    curl -fSL -o "${tmpdir}/x86_64.deb" "$x86_url" || {
        log_error "Failed to download x86_64 package"
        exit 1
    }

    log_info "Downloading aarch64 package..."
    curl -fSL -o "${tmpdir}/aarch64.deb" "$arm64_url" || {
        log_error "Failed to download aarch64 package"
        exit 1
    }

    # Calculate SHA256 checksums
    sha256sums_x86_64=$(sha256sum "${tmpdir}/x86_64.deb" | awk '{print $1}')
    sha256sums_aarch64=$(sha256sum "${tmpdir}/aarch64.deb" | awk '{print $1}')

    log_info "SHA256 checksums:"
    log_info "  x86_64: ${sha256sums_x86_64}"
    log_info "  aarch64: ${sha256sums_aarch64}"
}

# Detect electron version from downloaded package
detect_electron_version() {
    log_info "Detecting Electron version..."

    local tmpdir=$(mktemp -d)
    trap "rm -rf $tmpdir" EXIT

    local x86_url="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_${PKGVER}-${_x86minor}_amd64_${_x86check}.deb"

    curl -fSL -o "${tmpdir}/package.deb" "$x86_url"

    # Extract and check electron version
    cd "$tmpdir"
    ar -x package.deb
    tar -xf data.tar.xz

    local electron_version=$(jq --raw-output '.devDependencies.electron' < "usr/share/antigravity/resources/app/package.json" 2>/dev/null || echo "")

    if [[ -z "$electron_version" ]]; then
        log_warn "Could not detect Electron version, using electron39 as fallback"
        _electron="electron39"
    else
        local electron_major=$(echo "$electron_version" | sed 's/^[~^]\?\([0-9]\+\)\(\.[0-9]\+\)*$/\1/')
        _electron="electron${electron_major}"
        log_info "Detected Electron version: ${_electron}"
    fi

    cd - > /dev/null
}

# Generate updated PKGBUILD
generate_pkgbuild() {
    log_info "Generating PKGBUILD..."

    cat > PKGBUILD <<'PKGEOF'
# Maintainer: codev911 <codev911@mojosolid.dev>

pkgname=@PKGNAME@
pkgver=@PKGVER@
_x86minor=@X86MINOR@
_arm64minor=@ARM64MINOR@
_x86check=@X86CHECK@
_arm64check=@ARM64CHECK@
pkgrel=1
pkgdesc='An agentic development platform from Google, evolving the IDE into the agent-first era.'
arch=(aarch64 x86_64)
url='https://antigravity.google/'
license=(LicenseRef-Google-Antigravity)
_electron=@ELECTRON@
depends=(bash $_electron libx11 libxkbfile)
makedepends=(jq)
options=(!strip !debug)
source=($pkgname.sh)
source_aarch64=("Antigravity-$pkgver-aarch64.deb::https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_$pkgver-${_arm64minor}_arm64_${_arm64check}.deb")
source_x86_64=("Antigravity-$pkgver-x86_64.deb::https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_$pkgver-${_x86minor}_amd64_${_x86check}.deb")
sha256sums=('d3f365e6796836980a1439fb78be5cbfe1e11767fbd98fe695d3a953426d038b')
sha256sums_aarch64=('@SHA256AARCH64@')
sha256sums_x86_64=('@SHA256X86_64@')

prepare() {
    tar -xpf data.tar.xz

    # Find out which major release of electron this version of antigravity requires
    local _electron_major=$(jq --raw-output '.devDependencies.electron' < "usr/share/antigravity/resources/app/package.json" | sed 's/^[~^]\?\([0-9]\+\)\(\.[0-9]\+\)*$/\1/')

    # Check if we depend on the correct electron version
    if [ "$_electron" != "electron$_electron_major" ] ; then
        echo "Error: Incorrect electron version detected. Please change the value of \"_electron\" from \"$_electron\" to \"electron$_electron_major\"."
        return 1
    fi

    # Specify electron version in launcher (lib path stays /usr/lib/antigravity)
    sed -i "s|@ELECTRON@|$_electron|" "$srcdir/$pkgname.sh"
    sed -i "s|@LIB_PATH@|/usr/lib/antigravity|" "$srcdir/$pkgname.sh"

    sed -i 's|/usr/share/antigravity/antigravity|/usr/bin/antigravity|g' usr/share/applications/*.desktop
}

package() {
    install -Dm755 $pkgname.sh "$pkgdir/usr/bin/antigravity"

    cd usr/share/

    install -d "$pkgdir/usr/lib/antigravity"
    cp -a antigravity/resources/app/* "$pkgdir/usr/lib/antigravity/"

    install -d "$pkgdir/usr/share/licenses/$pkgname"
    ln -s /usr/lib/antigravity/LICENSE.txt "$pkgdir/usr/share/licenses/$pkgname/LICENSE.txt"

    # Note: files from deb use 'antigravity' name, not $pkgname
    install -Dm644 appdata/antigravity.appdata.xml -t "$pkgdir/usr/share/metainfo"

    install -Dm644 applications/antigravity.desktop -t "$pkgdir/usr/share/applications"
    install -Dm644 applications/antigravity-url-handler.desktop -t "$pkgdir/usr/share/applications"

    install -Dm644 bash-completion/completions/antigravity -t "$pkgdir/usr/share/bash-completion/completions"
    install -Dm644 zsh/vendor-completions/_antigravity -t "$pkgdir/usr/share/zsh/site-functions"

    install -Dm644 mime/packages/antigravity-workspace.xml -t "$pkgdir/usr/share/mime/packages"
    install -Dm644 pixmaps/antigravity.png -t "$pkgdir/usr/share/pixmaps"
    rm -rf "$pkgdir/usr/lib/resources/"
}
PKGEOF

    # Replace placeholders with actual values
    sed -i "s|@PKGNAME@|$PKGNAME|g" PKGBUILD
    sed -i "s|@PKGVER@|$PKGVER|g" PKGBUILD
    sed -i "s|@X86MINOR@|$_x86minor|g" PKGBUILD
    sed -i "s|@ARM64MINOR@|$_arm64minor|g" PKGBUILD
    sed -i "s|@X86CHECK@|$_x86check|g" PKGBUILD
    sed -i "s|@ARM64CHECK@|$_arm64check|g" PKGBUILD
    sed -i "s|@ELECTRON@|$_electron|g" PKGBUILD
    sed -i "s|@SHA256AARCH64@|$sha256sums_aarch64|g" PKGBUILD
    sed -i "s|@SHA256X86_64@|$sha256sums_x86_64|g" PKGBUILD

    log_info "PKGBUILD generated successfully"
}

# Update .SRCINFO
update_srcinfo() {
    log_info "Updating .SRCINFO..."
    makepkg --printsrcinfo > .SRCINFO
    log_info ".SRCINFO updated"
}

# Main execution
main() {
    log_info "Starting update process for ${PKGNAME}..."

    # Check for required tools
    for cmd in curl jq ar sha256sum; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done

    # Set maintainer info from env or use defaults
    MAINTAINER_NAME="${MAINTAINER_NAME:-Your Name}"
    MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-your.email@example.com}"

    fetch_version_info
    calculate_checksums
    detect_electron_version
    generate_pkgbuild
    update_srcinfo

    log_info "Update complete!"
    log_info "Version: ${PKGVER}"
    log_info "Electron: ${_electron}"
}

main "$@"
