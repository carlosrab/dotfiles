{
  description = "Homemanager lightweight flake for personal computer that should also allow for to quickly start working.";

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

    flake-utils.url = "github:numtide/flake-utils";

    # import the 1Password Shell Plugins Flake
    # https://developer.1password.com/docs/cli/shell-plugins/nix/
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs @ { self, darwin, nixpkgs, home-manager, ... }: {
    darwinConfigurations.lima = darwin.lib.darwinSystem {
      modules = [
        ./darwin/macos/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.carlos = import ./home/mac/home.nix;
          home-manager.sharedModules = [
            inputs._1password-shell-plugins.hmModules.default
          ];
        }
      ];
    };
    # homeConfigurations = {
    #   carlos = inputs.home-manager.lib.homeManagerConfiguration {
    #     pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    #     modules = [
    #       ./mbp-lima.nix
    #       inputs._1password-shell-plugins.hmModules.default
    #     ];
    #   };
    # };
  };
}
