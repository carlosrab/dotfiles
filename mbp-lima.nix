{ pkgs, lib, ... }:

{
  imports = [
    ./modules/alacritty.nix
    ./modules/git.nix
    ./modules/ssh.nix
    ./modules/zsh.nix
  ];

  # This is required information for home-manager to do its job
  home = {
    stateVersion = "24.05";
    username = "carlos";
    homeDirectory = "/Users/carlos";

    packages = with pkgs; [
      # improved utilities
      # better cat
      bat
      # better top
      btop
      # better du
      du-dust
      # system info
      neofetch
      # faster grep
      ripgrep
      # tldr but rust version. short help pages.
      tlrc

      # core
      curl
      # improved find
      fd
      gnupg
      # better ping
      gping
      openssl
      tmux
      wget

      # network tools
      nmap

      # nix lang related
      # language server
      nil
      nixpkgs-fmt

      #git
      # diff tool
      gitAndTools.delta
      #github
      gh
      #gitlab
      glab
      # terminal ui for git
      lazygit
    ];

    shellAliases = {
      # basic overrides
      cat = "bat";
      cd = "z";
      # top = "btop";
      # htop = "btop";
      la = "eza -lag --icons";
      ls = "eza -lg --icons";
      lt = "eza -Tla --icons --git --git-ignore";
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

      changeDirWidgetCommand = "fd --type d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = ["--preview 'eza --tree --color=always {} | head -200'"];

      # defaultCommand = "fd --type f --hidden --follow --exclude .git --exclude .vim --exclude .cache --exclude vendor --exclude node_modules";
      defaultCommand = "rg --files --hidden";
      defaultOptions = ["--preview 'bat -n --color=always --line-range :500 {}'"];

      fileWidgetCommand = "rg --files --hidden";
      fileWidgetOptions = ["--preview 'bat -n --color=always --line-range :500 {}'"];
    };

    # pretty ls
    eza = {
      enable = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  xdg.enable = true;
}
