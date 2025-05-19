# common/global-settings.nix
{ ... }: # Normally, pkgs or other parameters are not needed unless you want to make judgments based on the system type.
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;
  # system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
}