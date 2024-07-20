{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "carlos";
    userEmail = "49134466+carlosrab@users.noreply.github.com";

    delta = {
      enable = true;
      options = {
        syntax-theme = "solarized-dark";
        side-by-side = true;
      };
    };

    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      github.user = "carlosrab";
      gitlab.user = "carlosrab";

      push.autoSetupRemote = true;

      core.editor = "nvim";
      core.fileMode = false;
      core.ignorecase = false;
    };
  };
}
