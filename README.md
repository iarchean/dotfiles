# My Dotfiles Configuration

Welcome to my personal dotfiles and system configuration repository! This setup uses [Nix](https://nixos.org/) for package management and system configuration (on macOS via Nix-Darwin), and [GNU Stow](https://www.gnu.org/software/stow/) for managing symbolic links of dotfiles.

## Prerequisites

*   **A non-root user with `sudo` privileges.**
*   **Internet connection.**
*   **Git** (This will be installed if missing on macOS, instructions provided for Linux).
*   **(macOS only)** You might be prompted to install Xcode Command Line Tools if `git` is not found, using `xcode-select --install`.

## Installation Steps

Please follow the steps relevant to your operating system.

### 1. Install Nix Package Manager

If you don't have Nix installed, open your terminal and run the following command. This uses the [Determinate Systems Nix Installer](https://determinate.systems/posts/determinate-nix-installer), which is a recommended installer.

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix | sh -s -- install
```

After installation, **you MUST open a new terminal window or source the Nix profile script** for the `nix` command to be available:

```bash
# Run this in your current terminal, or simply open a new one
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

Verify Nix installation:
```bash
nix --version
```

### 2. Clone This Dotfiles Repository

Choose a location for these configuration files. A common choice is `~/dotfiles`.

```bash
# Ensure git is installed
# On Debian/Ubuntu: sudo apt update && sudo apt install git
# On Fedora: sudo dnf install git
# On Arch Linux: sudo pacman -S git
# On macOS: Xcode Command Line Tools (usually prompted if git is missing) should provide it.

git clone https://github.com/iarchean/dotfiles.git ~/dotfiles # Replace with your repo URL if different
cd ~/dotfiles
```

---

### 3. OS-Specific Setup

#### For macOS Users (using Nix-Darwin)

Nix-Darwin will be used to configure your macOS system declaratively and install system-wide packages, including GNU Stow (assuming it's defined in the flake).

1.  **Build and Apply the Nix-Darwin Configuration:**
    This command will read the `flake.nix` in this repository, build your system configuration, and then switch your system to use it. This process can take a while, especially on the first run.

    ```bash
    # Ensure you are in the dotfiles directory (e.g., ~/dotfiles)
    # cd ~/dotfiles/nix

    # This command builds the configuration and then applies it.
    # It might ask for your sudo password during the 'switch' phase.
    nix build .#darwinConfigurations.mac.system && ./result/sw/bin/darwin-rebuild switch --flake .#mac
    ```
    If you encounter permission issues with `nix build`, ensure your user has a correctly configured Nix environment. Running `darwin-rebuild` typically handles its own `sudo` needs.

2.  **Link Your Dotfiles with GNU Stow:**
    After `darwin-rebuild switch` completes successfully, `stow` (and other packages defined in your flake) should be installed and available in your `PATH`.

    *   Open a **new terminal window** to ensure all environment changes are loaded.
    *   Navigate to your dotfiles directory:
        ```bash
        cd ~/dotfiles
        ```
    *   Use `stow` to create symbolic links for your configuration files. For example, to link configurations for `nvim`, `fish`, and `tmux` (assuming you have directories named `nvim`, `fish`, `tmux` in `~/dotfiles`):
        ```bash
        stow nvim fish tmux
        ```
    *   To link all packages (subdirectories) in your dotfiles directory:
        ```bash
        stow */
        ```
        (Note: `stow .` would try to stow files in the current directory as well, `stow */` focuses on subdirectories which is common for Stow packages). Adjust based on your Stow setup.

3.  **(Optional) Restart:** Some system-level changes applied by Nix-Darwin might require a logout/login or a full restart to take full effect.

#### For Linux Users (Ubuntu, Arch Linux, etc. - Non-NixOS)

On Linux, Nix will be used as a package manager to provide tools like `stow` and your preferred applications. Your system itself is not managed by Nix in this setup.

1.  **Ensure Nix Environment is Active:**
    If you haven't already, open a new terminal or run:
    ```bash
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    ```

2.  **Install GNU Stow (and other tools) using Nix:**
    Navigate to your dotfiles directory (`cd ~/dotfiles`). You have a few options:

    *   **Install `stow` to your user profile (recommended for general availability):**
        ```bash
        nix profile install nixpkgs#stow
        ```
    *   **(Optional) Install a pre-defined set of tools from this flake (if available):**
        This flake might expose a package set (e.g., named `tools-linux`). Check the `flake.nix` outputs.
        ```bash
        # From within ~/dotfiles
        nix profile install .#tools-linux # Replace 'tools-linux' if your flake uses a different name
        ```
    *   **(Alternative) Use a Nix development shell:**
        This provides the tools only within the activated shell session.
        ```bash
        # From within ~/dotfiles
        nix develop .#env-linux # Replace 'env-linux' if your flake uses a different name
        ```
        You'll need to be in this shell to use `stow` if you choose this method.

3.  **Link Your Dotfiles with GNU Stow:**
    Once `stow` is available (either from your Nix profile or within a `nix develop` shell):

    *   Navigate to your dotfiles directory:
        ```bash
        cd ~/dotfiles
        ```
    *   Use `stow` to create symbolic links. For example:
        ```bash
        stow nvim fish tmux
        ```
    *   Or, to link all packages (subdirectories):
        ```bash
        stow */
        ```

---

## Usage

*   **macOS**: To update your system after making changes to the Nix configuration in this repository:
    ```bash
    cd ~/dotfiles
    git pull # Get latest changes if you version control your flake
    nix flake update # Optional: update flake inputs like nixpkgs
    nix build .#darwinConfigurations.mac.system && ./result/sw/bin/darwin-rebuild switch --flake .#mac
    ```

*   **Linux**:
    *   To update tools installed via `nix profile install`: You might need to update your flake inputs (`nix flake update` in `~/dotfiles`) and then re-run the `nix profile install .#tools-linux` command or update individual packages (e.g., `nix profile upgrade stow`).
    *   If using `nix develop`, exiting and re-entering the shell after a `git pull` and `nix flake update` will usually pick up changes.

## Troubleshooting

*   **`command not found: nix`**: Ensure you've opened a new terminal after installing Nix or sourced the profile script: `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`.
*   **`command not found: stow`**:
    *   **macOS**: Ensure `stow` is listed in `environment.systemPackages` in your Nix-Darwin configuration and `darwin-rebuild switch` completed successfully. Open a new terminal.
    *   **Linux**: Make sure you've installed `stow` via `nix profile install nixpkgs#stow` (and opened a new terminal) or are inside a `nix develop` shell where it's provided.
*   **Stow conflicts (`existing target is not a symlink` or `will not overwrite existing file` )**: This means Stow found an existing file or directory where it wants to create a symlink. You may need to manually back up and remove these conflicting files/directories from your home directory before running `stow`. For example, if `~/.config/nvim` exists and is not a symlink, Stow won't overwrite it unless you use options like `--adopt` (use with caution) or remove it first.


curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/init.sh | sudo sh

reference:
- https://github.com/omerxx/dotfiles
- https://zero-to-nix.com
- https://sandstorm.de/blog/posts/my-first-steps-with-nix-on-mac-osx-as-homebrew-replacement/
- https://xeiaso.net/blog/nix-flakes-1-2022-02-21/
- https://blog.6nok.org/how-i-use-nix-on-macos/
- https://nixcademy.com/cheatsheet/
- https://nixcademy.com/posts/nix-on-macos/
- https://github.com/ironicbadger/nix-config/blob/main/justfile


[TODO] nvim and tmux pane switch plugin
tmux shortcut to switch pane
show vim status in tmux status bar
