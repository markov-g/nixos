{ config, lib, pkgs, user, host, ... }:

{
  # ---------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------
  networking.hostName = host;
  networking.networkmanager.enable = true;

  time.timeZone = lib.mkDefault "America/New_York"; # <- CHANGE ME
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # ---------------------------------------------------------------------
  # Nix itself
  # ---------------------------------------------------------------------
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" user ];
      auto-optimise-store = true;
      warn-dirty = false;
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
  };

  # Run x86_64 binaries (some vendor SDKs, old JetBrains plugins) on aarch64.
  # Costs nothing until used, but does pull in qemu-user.
  boot.binfmt.emulatedSystems = lib.mkDefault [ "x86_64-linux" ];

  # ---------------------------------------------------------------------
  # nix-ld: lets FHS-expecting binaries run. This is what makes
  # JetBrains-Toolbox-installed IDEs, pip wheels with bundled .so files,
  # dotnet single-file apps and Linuxbrew bottles stand a chance.
  # ---------------------------------------------------------------------
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    zstd
    openssl
    curl
    glib
    glibc
    icu
    libGL
    libxkbcommon
    fontconfig
    freetype
    fuse3
    libx11
    libxext
    libxrender
    libxtst
    libxi
    libxrandr
    libxcb
    nss
    nspr
    dbus
    alsa-lib
    expat
  ];

  # AppImages (JetBrains Toolbox ships as one upstream).
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  services.envfs.enable = true; # /usr/bin/env shims for random scripts

  # ---------------------------------------------------------------------
  # Base system packages (parity with your darwin system.nix + more)
  # ---------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # editors / pagers
    vim
    neovim
    bat
    less

    # navigation
    eza
    fd
    ripgrep
    fzf
    zoxide
    autojump
    tree

    # session / monitoring
    tmux
    zellij
    btop
    htop
    iotop
    lsof
    strace
    ltrace

    # net
    curl
    wget
    rsync
    openssh
    mtr
    dig
    nmap
    socat
    netcat-gnu

    # data wrangling
    jq
    yq-go
    gnused
    gawk
    unzip
    zip
    p7zip
    xz

    # vcs
    git
    git-lfs
    gh
    lazygit
    delta
    difftastic

    # nix tooling
    nixpkgs-fmt
    nil
    nixd
    statix
    deadnix
    nix-tree
    nix-output-monitor
    nvd
    nh
    cachix
    direnv
    nix-direnv

    # misc
    just
    hyperfine
    tokei
    sqlite
    pciutils
    usbutils
  ];

  environment.variables.EDITOR = lib.mkForce "nvim";

  # ---------------------------------------------------------------------
  # Fonts (Nerd Fonts for the terminal + IDEs)
  # ---------------------------------------------------------------------
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-cove
    noto-fonts
    noto-fonts-color-emoji
    liberation_ttf
  ];
  fonts.fontconfig.defaultFonts.monospace = [ "JetBrainsMono Nerd Font" ];

  # ---------------------------------------------------------------------
  # Services
  # ---------------------------------------------------------------------
  # Resolve nixdevbox.local from macOS without knowing the VM's IP.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    openFirewall = true;
  };

  security.sudo.wheelNeedsPassword = false; # dev VM convenience
  security.polkit.enable = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22 # ssh
    ];
  };

  system.stateVersion = "26.05"; # do not change after first build
}
