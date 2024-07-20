{ pkgs, ... }: {
  # This is required information for home-manager to do its job
  home = {
    stateVersion = "23.11";
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
    ];
  };
  xdg.enable = true;

  programs.home-manager.enable = true;
  programs.neovim.enable = true;
}
