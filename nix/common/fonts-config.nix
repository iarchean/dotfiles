# common/fonts-config.nix
{ pkgs, lib }:
{
  # This section primarily applies to Nix-Darwin.
  # For other systems (Ubuntu, Arch, WSL), Nix won't manage system fonts directly.
  # You should install fonts using your system's package manager or manually.
  # This list serves as a reference for which fonts to install.
  fonts.packages = lib.mkIf pkgs.stdenv.isDarwin (with pkgs; [ # Only apply on Darwin
    maple-mono.truetype
    maple-mono.CN-unhinted
    maple-mono.NF-unhinted
    maple-mono.NF-CN-unhinted
  ]);

  # Notes for non-Darwin systems:
  # On Ubuntu/Debian:
  #   sudo apt install fonts-firacode fonts-jetbrains-mono ...
  # On Arch Linux:
  #   sudo pacman -S ttf-firacode-nerd ttf-jetbrains-mono-nerd ...
  # Or download from Nerd Fonts website and install to ~/.local/share/fonts, then run `fc-cache -fv`.
}