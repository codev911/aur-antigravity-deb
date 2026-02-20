# antigravity-deb AUR Package

Modified AUR package for [Antigravity](https://antigravity.google/) - Google's agentic development platform.

## Features

- Automatic version updates via GitHub Actions
- Custom launcher script with flags support
- Supports both `x86_64` and `aarch64` architectures

## Installation

### From this repository

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/antigravity-deb.git
   cd antigravity-deb
   ```

2. Build and install:
   ```bash
   makepkg -si
   ```

### From AUR (if published)

```bash
paru -S antigravity-deb
# or
yay -S antigravity-deb
```

## Configuration

The package reads flags from two configuration files (in order):

1. `~/.config/antigravity-flags.conf` - Application-specific flags
2. `~/.config/electron39-flags.conf` - Electron-specific flags (fallback)

Example `~/.config/antigravity-flags.conf`:
```bash
# Enable hardware acceleration
--enable-features=UseOzonePlatform
--ozone-platform=wayland

# Other flags
--disable-gpu-driver-bug-workarounds
```

## Development

### Manual Update

To manually update to the latest version:

```bash
./update.sh
```

This will:
1. Fetch the latest version from Google's repository
2. Download and verify the `.deb` packages
3. Calculate SHA256 checksums
4. Generate updated `PKGBUILD` and `.SRCINFO`

### Automatic Updates

This repository uses GitHub Actions to automatically check for updates every hour. When a new version is detected:

1. The `PKGBUILD` is automatically updated
2. A commit is created with the new version
3. A version tag is created and pushed

## Repository Structure

```
.
├── .github/workflows/
│   └── update.yml          # GitHub Actions workflow for auto-updates
├── update.sh               # Manual update script
├── PKGBUILD                # Arch Linux package build script
├── .SRCINFO                # AUR metadata (auto-generated)
├── antigravity-deb.sh   # Launcher script with flags support
└── README.md               # This file
```

## Credits

Based on the original Antigravity AUR package by:
- AlphaLynx <alphalynx at alphalynx dot dev>
- HurricanePootis <hurricanepootis@protonmail.com>

## License

Same as Antigravity (LicenseRef-Google-Antigravity)
