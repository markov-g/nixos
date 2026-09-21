{ config, lib, pkgs, user, ... }:

{
  users.mutableUsers = true; # set to false once you manage passwords declaratively

  users.users.${user} = {
    isNormalUser = true;
    description = "Development user";
    home = "/home/${user}";
    shell = pkgs.zsh;

    extraGroups = [
      "wheel" # sudo
      "networkmanager"
      "video" # DRM access for Hyprland
      "input"
      "audio"
      "podman"
      "kvm"
      "docker" # only populated if you enable dockerCompat's socket group
    ];

    # Set an initial password on first boot, then change it with `passwd`.
    # `initialPassword` is world-readable in the nix store - fine for a
    # throwaway lab VM, wrong for anything else. Use hashedPassword or
    # sops-nix if this VM ever holds anything real.
    initialPassword = lib.mkDefault "changeme";

    # Paste your Mac's public key here so `ssh devel@nixdevbox.local` works
    # immediately. Get it with: cat ~/.ssh/id_ed25519.pub
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAA... you@your-mac"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILv4gfqjm2qr2iU+P0RSYgf9WxLjW+bdeSZ6Cz4k05ua r1pp3r@r1pp3r"
    ];
  };

  # root gets no password login; use sudo from `devel`.
  users.users.root.hashedPassword = lib.mkDefault "!";

  programs.zsh.enable = true;
}
