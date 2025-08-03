{
  # inputs are other flake dependencies to make this main flake readable.
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      # url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # url = "github:nix-community/home-manager/release-24.11";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    # Helps spotlight discover nix-installed apps.
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    # import the 1Password Shell Plugins Flake
    # https://developer.1password.com/docs/cli/shell-plugins/nix/
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs @ { self, darwin, homebrew, home-manager, mac-app-util, nixpkgs, ... }:
    {
      darwinConfigurations.mbp =
        let
          system = "aarch64-darwin";
          username = "carlos";
        in
        darwin.lib.darwinSystem {
          modules = [
            ./darwin/configuration.nix
            mac-app-util.darwinModules.default
            homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                inherit system username;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home/home.nix;
              home-manager.sharedModules = [
                inputs._1password-shell-plugins.hmModules.default
              ];
            }
          ];
          specialArgs = {
            inherit system username;
          };
          system = system;
        };
    };
}
