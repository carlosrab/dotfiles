{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    # suggests a command based on input string so far.
    autosuggestion = {
      enable = true;
      highlight = "fg=cyan,bg=black,bold";
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
      ## p10k related configuraiton.
      source ~/.config/zsh/.p10k.zsh

      ## fzf-tab plugin that improves tab completion using fzf.
      # source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      # # disable sort when completing `git checkout`
      # zstyle ':completion:*:git-checkout:*' sort false
      # # set descriptions format to enable group support
      # # NOTE: don't use escape sequences here, fzf-tab will ignore them
      # zstyle ':completion:*:descriptions' format '[%d]'
      # # set list-colors to enable filename colorizing
      # zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      # # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
      # zstyle ':completion:*' menu no
      # # preview directory's content with eza when completing cd
      # zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      # # switch group using `<` and `>`
      # zstyle ':fzf-tab:*' switch-group '<' '>'
      
      ## Custom keybindings
      # cmd + <back arrow>
      bindkey '^[[1;9D' backward-word

      # alt + <back arrow>
      bindkey '^[^[[D' backward-word

      # cmd + <forward arrow>
      bindkey '^[[1;9C' forward-word

      # alt + <forward arrow>
      bindkey '^[^[[C' forward-word

      ## Additional fzf configuration
      # As far as I know I cannot manage this configruation directly using
      # home manager fzf definition. 
      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          ls)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          export|unset) fzf --preview "eval 'echo \$ {}'" "$@" ;;
          ssh)          fzf --preview 'dig {}' "$@" ;;
          *)            fzf --preview 'bat -n --color=always --line-range :500 {}' "$@" ;;
        esac
      }
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
