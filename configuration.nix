{ pkgs, lib, inputs, ... }:
{
  system.stateVersion = 5;

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
