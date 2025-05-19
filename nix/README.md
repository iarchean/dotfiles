# Archean's Nix Configuration

This is a cross-platform Nix configuration collection that supports both macOS and Linux systems. The configuration is managed using Nix Flakes, providing a unified development environment and system configuration.

## System Requirements

- Nix package manager (installed via Determinate Nix)
- Supported systems:
  - macOS (Apple Silicon/Intel)
  - Linux (x86_64/aarch64)
  - WSL

## Quick Start

1. Install Nix using Determinate Nix installer:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

3. Choose configuration method based on your system:

   ### macOS
   ```bash
   nix build .#darwinConfigurations.mac.system
   ./result/sw/bin/darwin-rebuild switch --flake .#mac
   ```

   ### Linux/WSL
   ```bash
   # Enter development environment
   nix develop .#env-linux
   
   # Or install toolset
   nix profile install .#tools-linux
   ```

## Configuration Structure

- `flake.nix`: Main configuration file, defines all system configurations and development environments
- `common/`: Common configurations
  - `base-packages.nix`: Base package configuration
  - `fonts-config.nix`: Font configuration
  - `global-settings.nix`: Global settings
- `hosts/`: System-specific configurations
  - `mac/`: macOS specific configuration
  - `linux/`: Linux specific configuration

## Features

- Cross-platform support (macOS/Linux)
- Unified development environment
- Fish shell as default shell
- Common development tools and configurations included
- Homebrew integration support (macOS)

## Customization

1. Modify `common/base-packages.nix` to add or remove base packages
2. Create or modify system-specific configurations in the `hosts/` directory
3. Adjust configurations in `flake.nix` as needed

## Notes

- Initial configuration may take some time as packages need to be downloaded and compiled
- Ensure sufficient disk space is available
- Backup important data before configuration

## Contributing

Issues and Pull Requests are welcome to improve the configuration.

## License

MIT License
