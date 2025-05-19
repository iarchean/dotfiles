#!/bin/bash
set -e

# Check if running with sudo
if [ "$(id -u)" -ne 0 ]; then
    print_error "Please run this script with sudo"
    print_message "Example: curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/init.sh | sudo sh"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    echo "macos";;
        Linux*)     echo "linux";;
        *)          echo "unknown";;
    esac
}

# Function to install git based on OS
install_git() {
    local os_=$1
    print_message "Checking for git..."
    if command -v git >/dev/null 2>&1; then
        print_message "Git is already installed."
        return 0
    fi

    print_message "Installing git..."
    case $os_ in
        "macos")
            print_message "Installing Xcode Command Line Tools..."
            # Attempt to run xcode-select as the user, sudo if needed but often GUI interaction is user-level
            if ! sudo -u "$SUDO_USER" xcode-select -p >/dev/null 2>&1; then
                print_message "Please install Xcode Command Line Tools. Opening installation prompt..."
                sudo -u "$SUDO_USER" xcode-select --install
                print_message "Waiting for Xcode Command Line Tools installation to complete..."
                print_message "Please follow the on-screen prompts. The script will continue after you confirm completion or if git becomes available."
                # This loop is a bit tricky as user interaction is required.
                # A better approach might be to instruct user and exit if not found after a while.
                local count=0
                while ! command -v git >/dev/null 2>&1 && [ $count -lt 60 ]; do # Wait up to 5 minutes
                    sleep 5
                    count=$((count+1))
                done
                if ! command -v git >/dev/null 2>&1; then
                     print_error "Git installation failed or timed out. Please install Xcode Command Line Tools manually and rerun."
                     exit 1
                fi
            fi
            print_message "Xcode Command Line Tools (or git) installation completed/verified."
            ;;
        "linux")
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update && apt-get install -y git
            elif command -v dnf >/dev/null 2>&1; then
                dnf install -y git
            elif command -v pacman >/dev/null 2>&1; then
                pacman -S --noconfirm git
            else
                print_error "Unsupported Linux distribution for automatic git installation. Please install git manually."
                exit 1
            fi
            ;;
    esac
    if ! command -v git >/dev/null 2>&1; then
        print_error "Git installation failed."
        exit 1
    fi
}

# Function to clone repository
clone_repo() {
    local repo_url="https://github.com/iarchean/dotfiles.git" # Your repo
    # Clone into SUDO_USER's home directory
    local target_dir="/home/$SUDO_USER/dotfiles"
    if [ "$(detect_os)" = "macos" ]; then
        target_dir="/Users/$SUDO_USER/dotfiles"
    fi

    # Ensure parent directory exists and $SUDO_USER can write to it (should be their home)
    # No need to `mkdir -p` for home itself usually

    if [ -d "$target_dir" ]; then
        print_warning "Dotfiles directory $target_dir already exists. Updating..."
        # Change ownership temporarily if needed, or run git pull as user
        # chown -R "$SUDO_USER:$SUDO_USER" "$target_dir" # If script was run as root initially creating dir
        cd "$target_dir"
        # Run git pull as the SUDO_USER
        if ! sudo -u "$SUDO_USER" git -C "$target_dir" pull; then
            print_error "Failed to pull updates for dotfiles repository."
            # Allow script to continue, maybe local changes exist
        fi
        cd - > /dev/null # Go back to previous directory
    else
        print_message "Cloning dotfiles repository to $target_dir..."
        if ! sudo -u "$SUDO_USER" git clone "$repo_url" "$target_dir"; then
            print_error "Failed to clone dotfiles repository."
            exit 1
        fi
    fi
    # Ensure correct ownership after clone/pull
    sudo chown -R "$SUDO_USER:$SUDO_USER" "$target_dir"
}

# Function to install Nix
install_nix() {
    if command -v nix >/dev/null 2>&1; then
        print_message "Nix command found. Sourcing profile for current (root) shell."
        if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
            . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        else
            # Fallback for older Nix or non-standard installations
            export PATH="/nix/var/nix/profiles/default/bin:$PATH"
        fi
        return 0
    fi

    print_message "Installing Nix..."
    if curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm; then
        print_message "Nix installation script completed."
    else
        print_error "Nix installation script failed."
        exit 1
    fi

    print_message "Sourcing Nix profile for current (root) shell..."
    if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    else
        print_warning "Nix profile script not found for root. Attempting to set PATH manually."
        export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    fi

    if ! command -v nix >/dev/null 2>&1; then
        print_error "Nix command not found after installation and sourcing profile."
        exit 1
    fi
    print_message "Nix command is available for the root script."

    print_message "Configuring nixpkgs registry..."
    if sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && nix registry add nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable"; then
       print_message "Nix registry configured for $SUDO_USER."
    else
       print_warning "Failed to configure Nix registry for $SUDO_USER. This might cause issues if user runs nix commands directly without sourcing profile."
       # Also try for root, as some nix commands in script might run as root
       if nix registry add nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable; then
           print_message "Nix registry configured for root."
       else
           print_warning "Failed to configure Nix registry for root."
       fi
    fi
}

# Function to ensure Stow is available for the user
ensure_stow_for_user() {
    local os_=$1
    print_message "Ensuring stow is available for user $SUDO_USER..."

    # Check if stow is already available to the user by trying to run it
    if sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && command -v stow >/dev/null 2>&1"; then
        print_message "Stow is already available to user $SUDO_USER (likely via Nix profile or system)."
        return 0
    fi

    # If on macOS, darwin-rebuild should have installed it if declared.
    # If on Linux, or if macOS check failed, install via Nix profile.
    if [ "$os_" = "linux" ] || ! sudo -u "$SUDO_USER" bash -c "command -v stow >/dev/null 2>&1"; then
        print_message "Stow not found for user $SUDO_USER. Installing stow via Nix profile..."
        local stow_install_script
        read -r -d '' stow_install_script <<EOF
set -e
echo "[USER SCRIPT for stow install] Sourcing Nix profile..."
if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
else
    echo "[USER SCRIPT for stow install][WARN] Nix profile script not found for sourcing."
    export PATH="/nix/var/nix/profiles/default/bin:\$PATH" # Fallback
fi
echo "[USER SCRIPT for stow install] Installing stow to user profile..."
nix profile install nixpkgs#stow
echo "[USER SCRIPT for stow install] Stow installation attempt finished."
EOF
        if sudo -u "$SUDO_USER" bash -c "$stow_install_script"; then
            print_message "Stow successfully installed to user $SUDO_USER's Nix profile."
            # Verify again
            if ! sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && command -v stow >/dev/null 2>&1"; then
                print_error "Stow still not found for user $SUDO_USER after Nix profile install. Check Nix setup."
                exit 1
            fi
        else
            print_error "Failed to install stow to user $SUDO_USER's Nix profile."
            print_warning "Attempting system-level stow installation as a fallback (Linux only)..."
            if [ "$os_" = "linux" ]; then
                if command -v apt-get >/dev/null 2>&1; then
                    apt-get install -y stow
                elif command -v dnf >/dev/null 2>&1; then
                    dnf install -y stow
                elif command -v pacman >/dev/null 2>&1; then
                    pacman -S --noconfirm stow
                else
                    print_error "Could not install stow via system package manager or Nix. Please install stow manually."
                    exit 1
                fi
                if ! sudo -u "$SUDO_USER" command -v stow >/dev/null 2>&1; then
                    print_error "System-level stow installation also failed to make it available to user."
                    exit 1
                fi
                print_message "Stow installed via system package manager."
            else
                print_error "Stow installation failed for macOS and fallback not applicable."
                exit 1
            fi
        fi
    fi
    print_message "Stow is now available for user $SUDO_USER."
}


# Function to setup dotfiles using stow
setup_dotfiles() {
    print_message "Setting up dotfiles for user $SUDO_USER..."
    local os_=$(detect_os)
    local dotfiles_dir_="/home/$SUDO_USER/dotfiles"
    local home_dir_="/home/$SUDO_USER"
    if [ "$os_" = "macos" ]; then
        dotfiles_dir_="/Users/$SUDO_USER/dotfiles"
        home_dir_="/Users/$SUDO_USER"
    fi

    if [ ! -d "$dotfiles_dir_" ]; then
        print_error "Dotfiles directory $dotfiles_dir_ does not exist!"
        exit 1
    fi

    print_message "Dotfiles directory: $dotfiles_dir_"
    print_message "Target home directory: $home_dir_"

    # The command string to be executed by $SUDO_USER
    read -r -d '' stow_script <<EOF
set -e
echo "[USER SCRIPT for stow] Running as: \$(whoami) in \$(pwd)"
echo "[USER SCRIPT for stow] Sourcing Nix profile (for PATH if stow from nix profile)..."
if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

echo "[USER SCRIPT for stow] Changing to dotfiles directory: ${dotfiles_dir_}"
cd "${dotfiles_dir_}" || { echo "[USER SCRIPT for stow][ERROR] Failed to cd to ${dotfiles_dir_}"; exit 1; }

echo "[USER SCRIPT for stow] Current directory: \$(pwd)"
echo "[USER SCRIPT for stow] Contents of current directory:"
ls -la
echo "[USER SCRIPT for stow] Checking for stow command..."
if ! command -v stow >/dev/null 2>&1; then
    echo "[USER SCRIPT for stow][ERROR] Stow command not found in PATH for user \$(whoami)!"
    echo "[USER SCRIPT for stow] PATH is: \$PATH"
    exit 1
fi
echo "[USER SCRIPT for stow] Stow command found at: \$(command -v stow)"
echo "[USER SCRIPT for stow] Running stow command..."
# Stow all packages (directories not starting with '.') in the current directory ($dotfiles_dir_)
# to the target directory ($home_dir_)
# Use --restow to handle existing links correctly.
# Use -v for verbose output.
stow -v --restow -t "${home_dir_}" -d "${dotfiles_dir_}" */  # Stow all top-level directories
# Or, if you want to stow everything including dotfiles at the root of $dotfiles_dir (e.g. .gitconfig)
# stow -v --restow -t "${home_dir_}" -d "${dotfiles_dir_}" .
echo "[USER SCRIPT for stow] Stow command finished."
EOF

    print_message "Will execute the stow script as user $SUDO_USER:"
    # echo "----------------------------------------------------"
    # echo "$stow_script" # Can be very verbose
    # echo "----------------------------------------------------"

    if sudo -E -u "$SUDO_USER" bash -c "$stow_script"; then # -E to preserve some env like HOME if needed
        print_message "Dotfiles setup completed successfully for user $SUDO_USER."
    else
        print_error "Dotfiles setup failed for user $SUDO_USER."
        exit 1
    fi
}

# Function to setup system based on OS
setup_system() {
    local os_=$1
    local dotfiles_flake_dir_="/home/$SUDO_USER/dotfiles" # Path to your flake.nix
    if [ "$os_" = "macos" ]; then
        dotfiles_flake_dir_="/Users/$SUDO_USER/dotfiles"
    fi

    case $os_ in
        "macos")
            print_message "Setting up macOS system using Nix-Darwin..."
            # Ensure the user running darwin-rebuild has the necessary Nix environment
            # darwin-rebuild usually needs to be run with sudo, but it acts on the system configuration
            # The flake path needs to be accessible.
            # We build first as the user to ensure permissions, then switch as root (or user with sudo)
            local build_cmd
            local switch_cmd

            build_cmd="cd '${dotfiles_flake_dir_}' && nix build .#darwinConfigurations.mac.system"
            switch_cmd="'${dotfiles_flake_dir_}/result/sw/bin/darwin-rebuild' switch --flake '${dotfiles_flake_dir_}#mac'"

            print_message "Building Darwin configuration as user $SUDO_USER..."
            if sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && $build_cmd"; then
                print_message "Darwin configuration built successfully."
            else
                print_error "Failed to build Darwin configuration."
                exit 1
            fi

            print_message "Switching to new Darwin configuration (requires sudo)..."
            # darwin-rebuild itself often handles sudo internally or prompts for it.
            # Running the whole command with sudo is safer.
            if bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && sudo $switch_cmd"; then # Note: sudo before the switch command
                print_message "Darwin system switched successfully."
            else
                print_error "Failed to switch Darwin system."
                # Attempt to run directly as root if above failed
                # print_warning "Retrying switch command with direct sudo..."
                # if sudo bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && $switch_cmd"; then
                #    print_message "Darwin system switched successfully (retry)."
                # else
                #    print_error "Failed to switch Darwin system on retry."
                #    exit 1
                # fi
                exit 1
            fi
            ;;
        "linux")
            print_message "Linux system setup (non-NixOS)."
            print_message "Core tools (including stow if Nix install succeeded) should be available via Nix profile for user $SUDO_USER."
            print_message "You can enter a more complete development environment from your dotfiles directory by running:"
            echo "cd $dotfiles_flake_dir_ && nix develop .#env-linux"
            print_message "Or install all tools from your flake to your profile:"
            echo "cd $dotfiles_flake_dir_ && nix profile install .#tools-linux"
            ;;
    esac
}

# Main execution
main() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "Please run this script with sudo"
        print_message "Example: curl -fsSL https://raw.githubusercontent.com/iarchean/dotfiles/main/scripts/init.sh | sudo sh"
        exit 1
    fi

    # It's crucial to know who the actual user is
    if [ -z "$SUDO_USER" ]; then
        print_error "SUDO_USER variable is not set. This script needs to be run with sudo by a regular user."
        exit 1
    fi
    print_message "Script running as root, for user: $SUDO_USER"

    local os_=$(detect_os)
    if [ "$os_" = "unknown" ]; then
        print_error "Unsupported operating system"
        exit 1
    fi
    print_message "Detected OS: $os_"

    install_git "$os_"
    clone_repo # Clones to $SUDO_USER's home
    install_nix # Installs Nix and sources profile for root script
    
    # After Nix is installed, for subsequent user-specific Nix commands,
    # ensure user's environment is set up.

    # For macOS, darwin-rebuild switch will install Stow if declared in environment.systemPackages
    # For Linux, explicitly install Stow to user's Nix profile if not already there.
    if [ "$os_" = "linux" ]; then
        ensure_stow_for_user "$os_"
    elif [ "$os_" = "macos" ]; then
        # On macOS, we assume darwin-rebuild will handle Stow installation.
        # We will run setup_system first, then setup_dotfiles.
        print_message "Deferring Stow check on macOS until after darwin-rebuild."
    fi

    # System setup (Nix-Darwin switch or Linux info)
    # This step on macOS should make stow available if it's in systemPackages
    setup_system "$os_"

    # If on macOS, now Stow *should* be available after darwin-rebuild.
    # Let's verify and if not, try to install it via profile as a backup.
    if [ "$os_" = "macos" ]; then
        if ! sudo -u "$SUDO_USER" bash -c ". /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && command -v stow >/dev/null 2>&1"; then
            print_warning "Stow not found for user $SUDO_USER after darwin-rebuild. Attempting Nix profile install..."
            ensure_stow_for_user "$os_" # This will try nix profile install
        fi
    fi
    
    setup_dotfiles # Uses stow, which should now be available to $SUDO_USER

    print_message "Initialization completed successfully!"
    print_message "For Linux: You might need to open a new terminal or run '. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' for Nix environment."
    print_message "For macOS: Changes from darwin-rebuild might require a logout/login or restart for some system settings to fully apply."
}

# Run main function
main