# Agamemnon Homebrew Tap

A custom Homebrew tap providing formulas and casks for Linux applications, including tools for ASUS laptops and popular browsers.

## Installation

To add this tap to your Homebrew installation:

```bash
brew tap agamemnon/homebrew-tap
```

## Available Packages

### Formulas

- **asusctl** - Control daemon and CLI tools for interacting with ASUS ROG laptops
  ```bash
  brew install asusctl
  ```

### Casks

- **google-chrome-linux** - Google Chrome web browser for Linux
  ```bash
  brew install --cask google-chrome-linux
  ```

- **zen-browser-linux** - Privacy-focused web browser based on Firefox
  ```bash
  brew install --cask zen-browser-linux
  ```

## Requirements

- Homebrew on Linux
- Some packages may require specific system dependencies (see individual formula/cask files for details)

## Contributing

This tap uses automated workflows for testing and publishing. Pull requests are welcome for new formulas or updates to existing ones.

## License

Individual packages maintain their own licenses. See the respective formula/cask files for license information.
