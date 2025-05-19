{ config, pkgs, lib, inputs, ... }:

let
  userName = "archean";
in
{
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = 6;
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
  system.primaryUser = userName;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    fish
    stow
  ];

  users.users.${userName}.shell = pkgs.fish;

  programs.fish.enable = true;

  environment.shells = [
    pkgs.fish
    pkgs.zsh
    pkgs.bash
  ];

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

  fonts.packages = with pkgs; [
    maple-mono.truetype
    maple-mono.NF-unhinted
    maple-mono.NF-CN-unhinted
  ];

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = false;

  security.pam.services.sudo_local.touchIdAuth = true;
# # macOS configuration
# system.activationScripts.postUserActivation.text = ''
#   # Following line should allow us to avoid a logout/login cycle
#   /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
# '';
# system.defaults = {
#   NSGlobalDomain.AppleShowAllExtensions = true;
#   NSGlobalDomain.AppleShowScrollBars = "Always";
#   NSGlobalDomain.NSUseAnimatedFocusRing = false;
#   NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
#   NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;
#   NSGlobalDomain.PMPrintingExpandedStateForPrint = true;
#   NSGlobalDomain.PMPrintingExpandedStateForPrint2 = true;
#   NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
#   NSGlobalDomain.ApplePressAndHoldEnabled = false;
#   NSGlobalDomain.InitialKeyRepeat = 25;
#   NSGlobalDomain.KeyRepeat = 2;
#   NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
#   NSGlobalDomain.NSWindowShouldDragOnGesture = true;
#   NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
#   LaunchServices.LSQuarantine = false; # disables "Are you sure?" for new apps
#   loginwindow.GuestEnabled = false;
#   finder.FXPreferredViewStyle = "Nlsv";
# };

# system.defaults.CustomUserPreferences = {
#     "com.apple.finder" = {
#       ShowExternalHardDrivesOnDesktop = true;
#       ShowHardDrivesOnDesktop = false;
#       ShowMountedServersOnDesktop = false;
#       ShowRemovableMediaOnDesktop = true;
#       _FXSortFoldersFirst = true;
#       # When performing a search, search the current folder by default
#       FXDefaultSearchScope = "SCcf";
#       DisableAllAnimations = true;
#       NewWindowTarget = "PfDe";
#       NewWindowTargetPath = "file://$\{HOME\}/Desktop/";
#       AppleShowAllExtensions = true;
#       FXEnableExtensionChangeWarning = false;
#       ShowStatusBar = true;
#       ShowPathbar = true;
#       WarnOnEmptyTrash = false;
#     };
#     "com.apple.desktopservices" = {
#       # Avoid creating .DS_Store files on network or USB volumes
#       DSDontWriteNetworkStores = true;
#       DSDontWriteUSBStores = true;
#     };
#     "com.apple.dock" = {
#       autohide = false;
#       launchanim = false;
#       static-only = false;
#       show-recents = false;
#       show-process-indicators = true;
#       orientation = "left";
#       tilesize = 36;
#       minimize-to-application = true;
#       mineffect = "scale";
#       enable-window-tool = false;
#     };
#     "com.apple.ActivityMonitor" = {
#       OpenMainWindow = true;
#       IconType = 5;
#       SortColumn = "CPUUsage";
#       SortDirection = 0;
#     };
#     "com.apple.Safari" = {
#       # Privacy: don’t send search queries to Apple
#       UniversalSearchEnabled = false;
#       SuppressSearchSuggestions = true;
#     };
#     "com.apple.AdLib" = {
#       allowApplePersonalizedAdvertising = false;
#     };
#     "com.apple.SoftwareUpdate" = {
#       AutomaticCheckEnabled = true;
#       # Check for software updates daily, not just once per week
#       ScheduleFrequency = 1;
#       # Download newly available updates in background
#       AutomaticDownload = 1;
#       # Install System data files & security updates
#       CriticalUpdateInstall = 1;
#     };
#     "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
#     # Prevent Photos from opening automatically when devices are plugged in
#     "com.apple.ImageCapture".disableHotPlug = true;
#     # Turn on app auto-update
#     "com.apple.commerce".AutoUpdate = true;
#     "com.googlecode.iterm2".PromptOnQuit = false;
#     "com.google.Chrome" = {
#       AppleEnableSwipeNavigateWithScrolls = true;
#       DisablePrintPreview = true;
#       PMPrintingExpandedStateForPrint2 = true;
#     };
# };
}