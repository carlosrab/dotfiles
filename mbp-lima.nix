{ pkgs, ... }: {
  # This is required information for home-manager to do its job
  home = {
    stateVersion = "23.11";
    username = "carlos";
    homeDirectory = "/Users/carlos";
    packages = [
      pkgs.git
      pkgs.neofetch
    ];
  };
  xdg.enable = true;

  programs.home-manager.enable = true;
}