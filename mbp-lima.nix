{ config, lib, libs, pkgs, ... }:

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
      # improved utilities
      bat # better cat
      btop # better top
      du-dust # better du
      lsd # ls delux
      neofetch # system info
      ripgrep # faster grep

      # core
      curl
      fd # improved find
      gnupg
      gping # better ping
      openssl
      tmux
      wget

      # network tools
      nmap

      # nix lang related
      nil # language server
      nixpkgs-fmt # formatter

      #git
      gitAndTools.delta
      gh #github
      glab #gitlab
      lazygit

      # zsh
      zsh-autocomplete
      zsh-autosuggestions
      zsh-powerlevel10k
      zsh-syntax-highlighting
    ];

    shellAliases = {
      # basic overrides
      cat = "bat";
      top = "btop";
      htop = "btop";
      ping = "gping";
      diff = "delta";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "1password-cli"
  ];

  programs = {
    home-manager.enable = true;
    neovim.enable = true;

    # 1password agent
    _1password-shell-plugins = {
      # enable 1Password shell plugins for bash, zsh, and fish shell
      enable = true;
      # the specified packages as well as 1Password CLI will be
      # automatically installed and configured to use shell plugins
      plugins = with pkgs; [ gh ];
    };

    # fast fuzzy search
    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand =
        "fd --type f --hidden --follow --exclude .git --exclude .vim --exclude .cache --exclude vendor --exclude node_modules";
    };

    # pretty ls
    lsd = {
      enable = true;
      enableAliases = true;
    };
  };

  xdg.enable = true;
}
