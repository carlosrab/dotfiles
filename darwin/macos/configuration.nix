{ pkgs, ... }:
{
  system.stateVersion = 5;
  ids.gids.nixbld = 30000;

  users.users.carlos = {
    name = "carlos";
    home = "/Users/carlos";
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
