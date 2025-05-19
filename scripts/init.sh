#!/bin/bash
# run after git clone

echo "Installing nix"
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate

echo "lazy-trees = true" | sudo tee -a /etc/nix/nix.custom.conf

echo "Installing stow"
# nix run "https://flakehub.com/f/NixOS/nixpkgs/*#stow" -- .
nix-env -iA "https://flakehub.com/f/NixOS/nixpkgs/*#stow"
