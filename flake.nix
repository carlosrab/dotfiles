{
  description = "Homemanager lightweight flake for personal computer that should also allow for to quickly start working.";

  # inputs are other flake dependencies to make this main flake readable.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-24.11";
      #url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # import the 1Password Shell Plugins Flake
    # https://developer.1password.com/docs/cli/shell-plugins/nix/
    _1password-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = inputs @ { self, nix-darwin, nixpkgs, nixpkgs-unstable, home-manager, flake-utils, ... }: {
    darwinConfigurations.lima = nix-darwin.lib.darwinSystem {
      modules = [ ./configuration.nix ];
      specialArgs = {
        inherit inputs;
      };
    };
    homeConfigurations = {
      carlos = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
        modules = [
          ./mbp-lima.nix
          inputs._1password-shell-plugins.hmModules.default
        ];
      };
    };
  };
}
