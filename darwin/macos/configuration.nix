{ pkgs, ... }:
{
  system.stateVersion = 5;
  ids.gids.nixbld = 30000;

  users.users.carlos = {
    name = "carlos";
    home = "/Users/carlos";
  };

  nix = {
    # This will allow you to use nix-darwin with Determinate. Some nix-darwin
    # functionality that relies on managing the Nix installation, like the
    # `nix.*` options to adjust Nix settings or configure a Linux builder,
    # will be unavailable.
    # enable = false;
    enable = true;
    # Necessary for using flakes on this system.
    settings.experimental-features = "nix-command flakes";
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };

  environment = {
    systemPackages = with pkgs; [
      devenv
    ];
  };

  nix-homebrew = {
    enable = true;

    # Apple Silicon Only
    enableRosetta = true;

    # User owning the Homebrew prefix
    user = "carlos";
  };

  homebrew = {
    enable = true;
    brews = [
      "mas"
    ];
    casks = [
      "ghostty"
    ];
    masApps = { };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
