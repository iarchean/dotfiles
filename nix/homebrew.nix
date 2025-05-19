{ config, pkgs, lib, inputs, ... }:

{
  nix-homebrew = {
    enable = true;
    user = "archean";
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # enableRosetta = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      # cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;
    brews = [
      # "bitwarden-cli"
    ];
    taps = [
      #"FelixKratz/formulae" #sketchybar
    ];
    casks = [
      "iina"
      "raycast"
    ];
    masApps = {
      # "Pages" = 409201541;
    };
  };
} 