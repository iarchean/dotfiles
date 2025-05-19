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

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

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
    local os=$1
    print_message "Installing git..."
    
    case $os in
        "macos")
            if ! command -v git >/dev/null 2>&1; then
                print_message "Installing Xcode Command Line Tools..."
                # Switch to the actual user for xcode-select
                sudo -u "$SUDO_USER" xcode-select --install
                
                # Wait for installation to complete
                print_message "Waiting for Xcode Command Line Tools installation to complete..."
                while ! sudo -u "$SUDO_USER" xcode-select -p >/dev/null 2>&1; do
                    sleep 5
                done
                print_message "Xcode Command Line Tools installation completed"
            fi
            ;;
        "linux")
            if command -v apt-get >/dev/null 2>&1; then
                apt-get update && apt-get install -y git
            elif command -v dnf >/dev/null 2>&1; then
                dnf install -y git
            elif command -v pacman >/dev/null 2>&1; then
                pacman -S --noconfirm git
            else
                print_error "Unsupported Linux distribution. Please install git manually."
                exit 1
            fi
            ;;
    esac
}

# Function to clone repository
clone_repo() {
    local repo_url="https://github.com/iarchean/dotfiles.git"
    local target_dir="/home/$SUDO_USER/dotfiles"
    
    if [ -d "$target_dir" ]; then
        print_warning "Dotfiles directory already exists. Updating..."
        cd "$target_dir"
        sudo -u "$SUDO_USER" git pull
    else
        print_message "Cloning dotfiles repository..."
        sudo -u "$SUDO_USER" git clone "$repo_url" "$target_dir"
        cd "$target_dir"
    fi
}

# Function to install Nix
install_nix() {
    print_message "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
    
    # Export Nix environment variables
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    
    # Initialize nixpkgs
    print_message "Initializing nixpkgs..."
    nix registry add nixpkgs github:NixOS/nixpkgs/nixpkgs-unstable
    
    # Set NIX_PATH
    export NIX_PATH="nixpkgs=github:NixOS/nixpkgs/nixpkgs-unstable${NIX_PATH:+:$NIX_PATH}"
    
    # Verify Nix installation
    if ! command -v nix >/dev/null 2>&1; then
        print_error "Nix installation failed or environment not properly set up"
        exit 1
    fi
}

# Function to setup dotfiles using stow
setup_dotfiles() {
    print_message "Setting up dotfiles..."
    
    # Use nix shell to run stow as the actual user
    cd "/home/$SUDO_USER/dotfiles"
    sudo -u "$SUDO_USER" env PATH="$PATH" NIX_PATH="$NIX_PATH" nix shell nixpkgs#stow --command "stow -t /home/$SUDO_USER -d /home/$SUDO_USER/dotfiles ."
}

# Function to setup system based on OS
setup_system() {
    local os=$1
    
    case $os in
        "macos")
            print_message "Setting up macOS system..."
            cd "/Users/$SUDO_USER/dotfiles"
            sudo -u "$SUDO_USER" env PATH="$PATH" NIX_PATH="$NIX_PATH" nix build .#darwinConfigurations.mac.system
            sudo -u "$SUDO_USER" env PATH="$PATH" NIX_PATH="$NIX_PATH" ./result/sw/bin/darwin-rebuild switch --flake .#mac
            ;;
        "linux")
            print_message "Setting up Linux system..."
            print_message "To enter the development environment, run:"
            echo "nix develop .#env-linux"
            ;;
    esac
}

# Main execution
main() {
    local os=$(detect_os)
    
    if [ "$os" = "unknown" ]; then
        print_error "Unsupported operating system"
        exit 1
    fi
    
    # Check and install git if needed
    if ! command -v git >/dev/null 2>&1; then
        install_git "$os"
    fi
    
    # Clone repository
    clone_repo
    
    # Install Nix
    install_nix
    
    # Setup dotfiles
    setup_dotfiles
    
    # Setup system
    setup_system "$os"
    
    print_message "Initialization completed successfully!"
    print_message "Please log out and log back in for all changes to take effect."
}

# Run main function
main
