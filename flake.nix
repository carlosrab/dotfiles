{
  # TODO: 
  # [x] define a convention for dotfiles.
  # [x] add git details and configure to push to gitlab/gh or other.
  # [x] ensure zsh is part of the basic setup with the proper configuration.
  # [x] stretch / break configuraiton into smaller modules if necessary
  # [] configure zsh ergonomics/plugins autocomplete, autosuggestion, fzf, lazygit?, bat, ripgrep.
  # [] test pushing this configuration to a remote/virtual/or new machine.
  # [] shell aliases
  # [] configure github/gitlab
  # [] autogenerate ssh if possible or use 1password cli to get ssh key.
  # [] configure tmux
  # [] configure nvim
  # 
  description = "Homemanager lightweight flake for personal computer that should also allow for to quickly start working.";

  # inputs are other flake dependencies to make this main flake readable.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }: {
    homeConfigurations = {
      carlos = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
        modules = [ ./mbp-lima.nix ];
        # extraSpecialArgs = { pkgsUnstable = inputs.nixpkgsUnstable.legacyPackages.aarch64-darwin; };
      };
    };
  };
}
