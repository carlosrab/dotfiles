{ pkgs, ... }:

{
  imports = [
    ../../modules/git.nix
    ../../modules/ssh.nix
    ../../modules/zsh.nix
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
      fastfetch
      # faster grep
      ripgrep
      # tldr but rust version. short help pages.
      tlrc

      # core
      curl
      # improved find
      fd
      gnupg

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
    ];

    shellAliases = {
      # basic overrides
      cat = "bat";
      cd = "z";

      # `.` works as a hack to work around some fzf-tab conflict for the ls alias.
      la = "eza -la --icons .";
      ls = "eza -l --icons .";
      lt = "eza -Tla -L=1 --icons --git --git-ignore .";
      diff = "delta";
    };
  };

  programs = {
    home-manager.enable = true;

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
      changeDirWidgetOptions = [ "--preview 'eza --tree --color=always {} | head -200'" ];

      defaultCommand = "fd --type f --hidden --follow --exclude .git";

      fileWidgetCommand = "rg --files --hidden";
      fileWidgetOptions = [ "--preview 'bat -n --color=always --line-range :500 {}'" ];
    };

    # pretty ls
    eza.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  xdg.enable = true;
}
