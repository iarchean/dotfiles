# hosts/mac/homebrew.nix
{ config, pkgs, lib, inputs, userName, ... }:
{
  nix-homebrew = {
    enable = true;
    user = userName;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };
    global.autoUpdate = true;
    brews = [
      "sslyze"
      "vnstat"
    ];
    taps = [ ];
    casks = [
      "iina"
      "alacritty"
      "cursor"
      "ghostty"
      "google-chrome"
      "itsycal"
      "kitty"
      "maczip"
      "notion"
      "obs"
      "orbstack"
      "prismlauncher"
      "raycast"
      "slack"
      "stats"
      "surge"
      "utm"
      "tailscale"
      "telegram"
      "wechat"
    ];
    masApps = { };
  };
}