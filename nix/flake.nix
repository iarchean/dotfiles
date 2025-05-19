{
  description = "Archean's cross-platform Nix configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = { url = "github:homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:homebrew/homebrew-cask"; flake = false; };
    # devenv.url = "github:cachix/devenv/latest";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
  let
    # aarch64-darwin for Apple Silicon Macs
    # x86_64-darwin for Intel Macs
    # x86_64-linux for most Linux PCs/Servers and WSL
    # aarch64-linux for ARM-based Linux (e.g., Raspberry Pi, some servers, some WSL on ARM Windows)
    supportedSystems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];

    forAllSystems = func: nixpkgs.lib.genAttrs supportedSystems (system: func {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          # self.overlays.default 
        ];
      };
      inherit system;
    });

    userName = "archean";

    commonGlobalSettings = import ./common/global-settings.nix;
    commonBasePackages = pkgs: (import ./common/base-packages.nix { inherit pkgs; }).packages;
    commonFontsConfig = pkgs: import ./common/fonts-config.nix { inherit pkgs; lib = pkgs.lib; };

    # Load Linux-specific extra packages
    linuxExtraPackages = pkgs: (import ./hosts/linux/extra-packages.nix { inherit pkgs; }).packages;

  in
  {
    # macOS Configuration
    darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit inputs userName;
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
      };
      modules = [
        commonGlobalSettings
        (commonFontsConfig nixpkgs.legacyPackages.aarch64-darwin)
        nix-homebrew.darwinModules.nix-homebrew
        ./hosts/mac/configuration.nix
        ./hosts/mac/homebrew.nix
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;
          environment.systemPackages = commonBasePackages pkgs;
          users.users.${userName}.shell = pkgs.fish;
          programs.fish.enable = true;
          environment.shells = with pkgs; [ fish zsh bash ];
          system.primaryUser = userName;
        })
      ];
    };

    # Provide a development environment for Linux (Ubuntu, Arch) and WSL
    # Use `nix develop .#env-linux` (or `#env-wsl`)
    devShells = forAllSystems ({ pkgs, system }:
      if pkgs.stdenv.isLinux then { # 只为 Linux 系统生成
        "env-${if pkgs.stdenv.isLinux then "linux" else "unknown"}" = pkgs.mkShell {
          name = "archean-env-${system}";
          packages = (commonBasePackages pkgs) ++ (linuxExtraPackages pkgs);
          shellHook = ''
            echo "Welcome to Archean's ${system} Nix environment!"
            echo "Core tools (nvim, fish, tmux, stow, etc.) and Linux extras are available."
            echo "Remember to clone your dotfiles and use 'stow' to set them up."
            # You can set some aliases or functions for fish or bash here, which are only valid in this shell.
            # export MY_ENV_VAR="hello from nix shell"
          '';
          # FISHELL=$(command -v fish)
          # if [ -n "$FISHELL" ]; then
          #   echo "Switching to Fish shell..."
          #   exec $FISHELL
          # fi
        };
      } else {}
    );

    # (Optional) Provide a packable toolset for easy `nix profile install .#tools-linux`
    packages = forAllSystems ({ pkgs, system }:
      if pkgs.stdenv.isLinux then {
        "tools-${if pkgs.stdenv.isLinux then "linux" else "unknown"}" = pkgs.symlinkJoin {
          name = "archean-tools-${system}";
          paths = (commonBasePackages pkgs) ++ (linuxExtraPackages pkgs);
          # meta.mainProgram = "fish";
        };
      } else {}
    );

    # # Overlays
    # overlays.default = import ./overlays/default.nix;
  };
}