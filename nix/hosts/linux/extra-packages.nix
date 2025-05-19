{ pkgs }:
{
  packages = with pkgs; [
    # Only needed for Linux environments (Ubuntu, Arch, WSL)
    # For example:
    # build-essential # (or its equivalent, such as gcc, gnumake, glibc.dev, etc., depending on your needs)
    # docker          # If you use Docker on Linux
    # python3Full
    # nodejs_20       # (or the version you need)
    # libnotify       # For desktop notifications
    # pavucontrol     # PulseAudio volume control (X11/Wayland)
    # util-linux      # (for lsblk, fdisk, etc.)
    # xclip           # X11 clipboard utility (or wl-clipboard for Wayland)
  ];
}