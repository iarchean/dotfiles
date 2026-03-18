# My Dotfiles Configuration

This repo restores my environment in a simple order:

- macOS: install Homebrew -> `brew bundle` -> `stow` dotfiles -> `mise install` -> apply `.macos`
- Other platforms: install base packages with the system package manager -> `stow` dotfiles -> install `mise` -> `mise install` -> apply any platform-specific settings manually

## Prerequisites

- A non-root user with `sudo` privileges
- Internet connection
- `git`

## Restore Flow

### macOS

1. Install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Clone the repository:

```bash
git clone https://github.com/iarchean/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

3. Restore apps and CLI tools:

```bash
brew bundle --file=~/dotfiles/Brewfile
```

4. Restore dotfiles:

```bash
stow --dir ~/dotfiles --target ~ --restow .config .mackup
```

5. Restore development tools managed by `mise`:

```bash
mise install
```

6. Apply macOS preferences:

```bash
bash ~/dotfiles/.macos
```

### Linux and other platforms

1. Install the base tools you need with your package manager. At minimum:

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y git stow

# Fedora
sudo dnf install -y git stow

# Arch Linux
sudo pacman -Sy --noconfirm git stow
```

2. Clone the repository:

```bash
git clone https://github.com/iarchean/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

3. Restore dotfiles:

```bash
stow --dir ~/dotfiles --target ~ --restow .config .mackup
```

4. Install `mise`:

```bash
curl -fsSL https://mise.run | sh
```

5. Restore development tools:

```bash
mise install
```

6. Apply any platform-specific settings manually.

## Bootstrap Script

You can also use the bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/bootstrap.sh | sudo sh
```

Current script behavior:

- `scripts/bootstrap.sh`: clones or updates `~/dotfiles`, then runs local `~/dotfiles/scripts/init.sh`
- `scripts/init.sh`: applies the local restore flow from the checked out repo
- macOS: installs Homebrew if needed, runs `brew bundle`, runs `stow`, runs `mise install`, then runs `.macos`
- Linux: installs `git` and `stow` if needed, runs `stow`, installs `mise` if needed, then runs `mise install`

## Update

### macOS

```bash
cd ~/dotfiles
git pull
brew bundle --file=~/dotfiles/Brewfile
stow --dir ~/dotfiles --target ~ --restow .config .mackup
mise install
bash ~/dotfiles/.macos
```

### Linux and other platforms

```bash
cd ~/dotfiles
git pull
stow --dir ~/dotfiles --target ~ --restow .config .mackup
mise install
```

## Troubleshooting

- `command not found: brew`: install Homebrew first on macOS
- `command not found: stow`: install `stow` with your system package manager or Homebrew
- `command not found: mise`: run `curl -fsSL https://mise.run | sh`, make sure `~/.local/bin` is in your `PATH`, then reopen the shell and run `mise install`
- Stow conflict errors: move or remove the existing target file before running `stow`

## Reference

- https://github.com/omerxx/dotfiles

[TODO] nvim and tmux pane switch plugin
tmux shortcut to switch pane
show vim status in tmux status bar
