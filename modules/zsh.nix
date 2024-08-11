{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    # suggests a command based on input string so far.
    autosuggestion = {
      enable = true;
      highlight = "fg=black,bg=cyan,bold";
    };
    # completion options when pressing tab after writing a command or part of it.
    enableCompletion = true;

    history = {
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true; # ignore commands starting with a space
      save = 40000;
      size = 40000;
      share = true;
    };

    # Equivalent to adding:
    # bindkey '^[[A' history-search-backward
    # bindkey '^[[B' history-search-forward
    historySubstringSearch.enable = true;

    initExtraFirst = ''
      # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
      # Initialization code that may require console input (password prompts, [y/n]
      # confirmations, etc.) must go above this block; everything else may go below.
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
    '';

    initExtra = ''
      source ~/.config/zsh/.p10k.zsh
      
      # cmd + <back arrow>
      bindkey '^[[1;9D' backward-word
      # cmd + <forward arrow>
      bindkey '^[[1;9C' forward-word
    '';

    plugins = [
      {
        name = "powerlevel10k-config";
        src = ./p10k;
        file = "p10k.zsh";
      }
      {
        name = "zsh-powerlevel10k";
        src = "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/";
        file = "powerlevel10k.zsh-theme";
      }
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        # replaces standard zsh-syntax-highlighting but does not appear to be much different.
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
    ];
  };
}
