{ pkgs, ... }:

{
  imports = [
    ./modules/git.nix
    ./modules/zsh.nix
  ];

  # This is required information for home-manager to do its job
  home = {
    stateVersion = "24.05";
    username = "carlos";
    homeDirectory = "/Users/carlos";
    packages = with pkgs; [
      # super basic
      git
      neofetch
      gnupg
      tmux
      wget

      # secondary tools
      ripgrep
      fzf

      # nix lang related
      nil
      nixpkgs-fmt

      # zsh
      zsh-autocomplete
      zsh-autosuggestions
      zsh-fzf-history-search
      zsh-powerlevel10k
      zsh-syntax-highlighting

      #git
      lazygit
    ];
  };
  xdg.enable = true;

  programs.home-manager.enable = true;
  programs.neovim.enable = true;
}
