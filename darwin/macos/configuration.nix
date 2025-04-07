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
}
