# Agamemnon Homebrew Tap

A custom Homebrew tap providing formulas and casks for Linux applications, with a focus on ASUS laptop tools, privacy-focused browsers, modern terminal emulators, and development tools. Features automated CI/CD workflows for bottle building and version updates.

## Installation

To add this tap to your Homebrew installation:

```bash
brew tap agammemnon/homebrew-tap
```

## Available Packages

### Formulas

Formulas are built from source and support pre-compiled bottles for faster installation.

- **asusctl** - Control daemon and CLI tools for interacting with ASUS ROG laptops
  ```bash
  brew install agammemnon/tap/asusctl
  ```
  *Includes RGB lighting control, fan profiles, and power management for ASUS ROG devices*

- **foundry** - CLI development tool for building IDE-like environments (GNOME project)
  ```bash
  brew install agammemnon/tap/foundry
  ```
  *Command-line interface for project management and development workflows*

### Casks

Casks provide pre-built GUI applications with desktop integration.

#### Browsers

- **google-chrome-linux** - Google Chrome web browser
  ```bash
  brew install --cask agammemnon/tap/google-chrome-linux
  ```

- **zen-browser-linux** - Privacy-focused web browser based on Firefox
  ```bash
  brew install --cask agammemnon/tap/zen-browser-linux
  ```

- **helium-browser-linux** - Open-source browser based on ungoogled-chromium
  ```bash
  brew install --cask agammemnon/tap/helium-browser-linux
  ```

#### Development Tools

- **ghostty-linux** - Fast, feature-rich, and native terminal emulator
  ```bash
  brew install --cask agammemnon/tap/ghostty-linux
  ```

- **zed-linux** - High-performance, multiplayer code editor
  ```bash
  brew install --cask agammemnon/tap/zed-linux
  ```

## Features

- **Automated Bottle Building**: Formulas are automatically built and bottled via GitHub Actions for faster installation
- **Version Updates**: Automated workflows check for new releases and update casks
- **Desktop Integration**: All GUI applications include proper `.desktop` files and icons
- **systemd Support**: Services for system-level tools like asusctl

## Usage Tips

### Building from Source

If you prefer to build formulas from source instead of using bottles:

```bash
brew install --build-from-source agammemnon/tap/<formula-name>
```

### Desktop Integration

Casks automatically install desktop files to `~/.local/share/applications/` and icons to `~/.local/share/icons/`. Applications should appear in your application launcher after installation.

### Post-Install Configuration

Some packages require additional setup:

- **asusctl**: Requires systemd service installation (see post-install instructions)
- **foundry**: Requires GSettings schema compilation (see post-install instructions)

Run `brew info <package-name>` to view detailed post-install instructions.

## Requirements

- Homebrew on Linux
- systemd (for asusctl)
- Some packages may require additional system dependencies (automatically installed via Homebrew)

## Troubleshooting

### GSettings Schema Errors

If you encounter GSettings-related errors with foundry, ensure you've compiled the schemas:

```bash
glib-compile-schemas $(brew --prefix foundry)/share/glib-2.0/schemas
export GSETTINGS_SCHEMA_DIR=$(brew --prefix foundry)/share/glib-2.0/schemas:$GSETTINGS_SCHEMA_DIR
```

### systemd Service Issues

For asusctl, verify services are running:

```bash
sudo systemctl status asusd.service
systemctl --user status asusd-user.service
```

### Desktop Files Not Appearing

If installed applications don't appear in your launcher, try updating the desktop database:

```bash
update-desktop-database ~/.local/share/applications/
```

## Documentation

Detailed technical documentation is available in the `docs/` directory:

- `foundry-homebrew-debugging.md` - Debugging notes for foundry formula

## Contributing

This tap uses automated workflows for testing and publishing:

- **Bottle Building**: Triggered via GitHub Actions for formulas
- **Version Updates**: Automated checks for new cask releases
- **Testing**: CI runs tests on all formulas

Pull requests are welcome for:
- New formulas or casks
- Version updates
- Bug fixes
- Documentation improvements

Please ensure formulas/casks follow Homebrew conventions and test locally before submitting.

## License

Individual packages maintain their own licenses:
- **asusctl**: MPL-2.0
- **foundry**: LGPL-2.1-or-later
- **Browsers and GUI apps**: See respective upstream projects

See individual formula/cask files for complete license information.
