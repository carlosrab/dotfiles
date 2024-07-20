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

      # nix lang related
      nil
      nixpkgs-fmt

      # zsh
      zsh-autocomplete
      zsh-autosuggestions
      zsh-powerlevel10k
      zsh-syntax-highlighting

      #git
      lazygit
    ];
  };

  xdg.enable = true;

  programs = {
    home-manager.enable = true;
    neovim.enable = true;

    fzf = {
      enable = true;
      enableZshIntegration = true;
      # defaultCommand =
      #   "fd --type f --hidden --follow --exclude .git --exclude .vim --exclude .cache --exclude vendor --exclude node_modules";
      # defaultOptions = [
      #   "--border sharp"
      #   "--inline-info"
      # ];
    };
  };
}
