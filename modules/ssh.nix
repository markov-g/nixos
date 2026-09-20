{ config, lib, pkgs, user, ... }:

{
  services.openssh = {
    enable = true;
    ports = [ 22 ];

    settings = {
      PermitRootLogin = "no";

      # TRADE-OFF, read this.
      # true  = you can log in before you've installed a key (safe bootstrap,
      #         but a password-guessable sshd).
      # false = key-only. Flip to false AFTER adding your key in users.nix
      #         and confirming `ssh devel@nixdevbox.local` works.
      PasswordAuthentication = lib.mkDefault true;

      KbdInteractiveAuthentication = false;
      X11Forwarding = true; # for the occasional GUI tool over ssh -X
      AllowUsers = [ user ];
      MaxAuthTries = 4;
      ClientAliveInterval = 60;
      ClientAliveCountMax = 5;
    };

    # Remote IDEs (JetBrains Gateway, VS Code Remote-SSH) want to run their
    # own agent. nix-ld (see system.nix) is what makes that agent binary work.
    extraConfig = ''
      AcceptEnv LANG LC_* TERM COLORTERM
      StreamLocalBindUnlink yes
    '';
  };

  # Agent forwarding target + a local agent for git pushes from the VM.
  programs.ssh.startAgent = true;

  # mosh survives the VM being suspended with the Mac lid closed.
  programs.mosh.enable = true;
  networking.firewall.allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];
}
