{ pkgs, username, ... }:

{
  # This is required because of some conflict with determinate nix.
  ids.gids.nixbld = 30000;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  nix = {
    # This will allow you to use nix-darwin with Determinate. Some nix-darwin
    # functionality that relies on managing the Nix installation, like the
    # `nix.*` options to adjust Nix settings or configure a Linux builder,
    # will be unavailable.
    enable = false;
    # enable = true;
    # Necessary for using flakes on this system.
    # settings.experimental-features = "nix-command flakes";
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  environment = {
    systemPackages = with pkgs; [
      aerospace
      code-cursor
      devenv
      direnv
      neovim
      raycast
      stow
      obsidian
      vscode
    ];
  };

  nix-homebrew = {
    enable = true;

    # Apple Silicon Only
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = username;
  };

  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "claude-code"
      "ghostty"
      "google-chrome"
      "google-drive"
      "linearmouse"
      "mullvad-vpn"
      "parallels"
      "synology-drive"
    ];
    masApps = {
      "WhatsApp" = 310633997;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.fira-mono
    nerd-fonts.sauce-code-pro
  ];

  system = {
    primaryUser = username;

    defaults = {
      dock = {
        autohide = true;
        orientation = "left";
        persistent-apps = [
          "/Applications/Firefox.app"
          "/System/Applications/System Settings.app"
        ];
        show-recents = false;

        # Hot corners
        wvous-bl-corner = 11; # launchpad
        wvous-br-corner = 4; # desktop

        # Reorginize spaces based on recent use.
        mru-spaces = false;
      };

      finder = {
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "Nlsv";
        FXRemoveOldTrashItems = true;
        NewWindowTarget = "Home";
        ShowPathbar = true;
        ShowStatusBar = true;
      };

      hitoolbox.AppleFnUsageType = "Change Input Source";

      NSGlobalDomain = {
        "com.apple.keyboard.fnState" = true;
        AppleICUForce24HourTime = true;
        KeyRepeat = 2;

      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerTapGesture = 2;
      };

      universalaccess.reduceMotion = true;
    };
  };

  system.stateVersion = 5;
}
