{ config, pkgs, lib, libs, ... }:
{
  programs.git = {
    enable = true;
    userName = "carlos";
    userEmail = "49134466+carlosrab@users.noreply.github.com";

    aliases = {
      # e.g., g cm or g ca
      cm = "commit";
      ca = "commit --amend --no-edit";
      co = "checkout";

      di = "diff";

      pu = "pull";
      ps = "push";

      sa = "add .";
      st = "status -sb";

      ri = "rebase -i";
      rc = "rebase --continue";
    };

    delta = {
      enable = true;

      options = {
        syntax-theme = "solarized-dark";
        side-by-side = true;
      };
    };

    extraConfig = {
      core.editor = "nvim";
      core.fileMode = false;
      core.ignorecase = false;

      delta.line-numbers = true;

      github.user = "carlosrab";
      gitlab.user = "carlosrab";
      init.defaultBranch = "main";

      pull.rebase = true;
      push.autoSetupRemote = true;
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
