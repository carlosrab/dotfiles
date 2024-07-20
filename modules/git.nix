{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "carlos";
    userEmail = "49134466+carlosrab@users.noreply.github.com";

    aliases = {
      gcm = "commit";
      gca = "commit --amend --no-edit";
      gco = "checkout";

      gdi = "diff";

      gpu = "pull";
      gps = "push";

      gst = "status -sb";

      gri = "rebase -i";
      grc = "rebase --continue";
    };

    delta = {
      enable = true;
      line-numbers = true;
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

    ignores = [
      # ide
      ".idea"
      ".vs"
      ".vsc"
      ".vscode"
      # npm
      "node_modules"
      "npm-debug.log"
      # python
      "__pycache__"
      "*.pyc"

      ".ipynb_checkpoints" # jupyter
      "__sapper__" # svelte
      ".DS_Store" # mac
      "kls_database.db" # kotlin lsp
    ];
  };
}
