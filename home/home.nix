# This is a system agnostic home module.
# Do not add any platform specific pkgs or configuration here.
{ pkgs, config, username, ... }:

{
  imports = [
    ./modules/git.nix
    ./modules/ssh.nix
    ./modules/zsh.nix
  ];

  xdg.enable = true;
  xdg.configFile."aerospace/aerospace.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/code/dotfiles/aerospace/aerospace.toml";

  # This is required information for home-manager to do its job
  home = {
    stateVersion = "25.11";
    username = username;
    homeDirectory = "/Users/${username}";

    packages = with pkgs; [
      # git
      # github
      gh
      # gitlab
      glab

      # network tools
      curl
      gnupg
      nmap
      openssl
      wget

      # nix lang related
      # language server
      nil
      nixpkgs-fmt

      # search
      fd
      ripgrep

      # session
      tmux
      zellij

      # system info
      fastfetch

      # utilities
      bat
      btop
      dust
      tlrc # short help pages
    ];

    sessionVariables = {
      EDITOR = "nvim";
    };

    shellAliases = {
      # basic overrides
      cat = "bat";
      cd = "z";

      # --icons as the last flag results in useless flag related suggestions not
      # directories.
      la = "eza --icons -la";
      ls = "eza --icons -l";
      lt = "eza --icons -L=1 --git --git-ignore -Tla";
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

    # ls
    eza.enable = true;

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
