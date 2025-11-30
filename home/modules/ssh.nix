{ ... }:
{
  # New setup does not appear to have an effect...
  programs.ssh.enableDefaultConfig = false;
  programs.ssh.matchBlocks."*".extraOptions = {
    # 1Password SSH Agent
    # https://developer.1password.com/docs/ssh/get-started/#step-4-configure-your-ssh-or-git-client 
    IdentityAgent = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # Old setup.
  # programs.ssh = {
  #   extraConfig = ''
  #     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  #   '';
  # };
}
