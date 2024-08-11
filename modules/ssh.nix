{ ... }:
{
  programs.ssh = {
    enable = true;
    extraConfig = ''
    # 1Password SSH Agent
    # https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client 
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    # IdentityAgent "/Users/carlos/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    # IdentityAgent "~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"

    ## START GITPOD INTEGRATION
    ## This section is managed by Gitpod. Any manual changes will be lost.
    Include "code_gitpod.d/config"
    ## END GITPOD INTEGRATION
    '';
  };
}