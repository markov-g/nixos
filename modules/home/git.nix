{ config, lib, pkgs, ... }:

# IMPORTANT: omarchy-nix already sets programs.git.userName and
# programs.git.userEmail from omarchy.full_name / omarchy.email_address.
# Those are deliberately NOT set here - defining them twice is an eval error.
# Change your identity in flake.nix instead.

{
  programs.git = {
    enable = true;

    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      rebase.autoStash = true;
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3";
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";

      # Shared folders mounted from macOS have odd ownership.
      safe.directory = [ "/mnt/mac/*" ];
    };

    aliases = {
      st = "status -sb";
      co = "checkout";
      sw = "switch";
      br = "branch";
      lg = "log --oneline --graph --decorate --all";
      last = "log -1 HEAD --stat";
      amend = "commit --amend --no-edit";
    };

    ignores = [
      "*.swp"
      ".DS_Store"
      ".direnv/"
      "result"
      "result-*"
      ".idea/"
      ".vscode/"
      "__pycache__/"
      ".venv/"
      "target/"
      "bin/"
      "obj/"
    ];
  };

  programs.gh.enable = true;
  programs.lazygit.enable = true;

  programs.ssh = {
    enable = true;

    matchBlocks."*".extraOptions = {
      AddKeysToAgent = "yes";
      ServerAliveInterval = "60";
    };

    matchBlocks."code.siemens.com" = {
      user = "git";
      identityFile = "~/.ssh/id_rsa_code_siemens_com";
    };

    # GitHub over 443 - SSH-over-HTTPS endpoint, for networks that block
    # outbound port 22. Carried over from the Mac config.
    matchBlocks."github.com" = {
      hostname = "ssh.github.com";
      port = 443;
      user = "git";
      identityFile = "~/.ssh/id_rsa";
      identitiesOnly = true;
      serverAliveInterval = 900;
      extraOptions.TCPKeepAlive = "yes";
    };
  };
}
