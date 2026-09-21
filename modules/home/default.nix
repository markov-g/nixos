{ config, lib, pkgs, user, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./ai-dotfiles.nix
    ./spacemacs.nix
  ];

  programs.home-manager.enable = true;

  home.username = user;
  home.homeDirectory = "/home/${user}";
  home.stateVersion = "26.05";

  # User-level packages. System-wide toolchains live in modules/dev/.
  home.packages = with pkgs; [
    direnv
    nix-direnv
    autojump
    starship
    atuin # shell history, syncs across machines if you want
    tealdeer # tldr
    glow
    yazi
    television
  ];

  # XDG hygiene so dotfiles don't sprawl.
  xdg.enable = true;
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    "$HOME/.dotnet/tools"
  ];

  # SPICE session agent. The system daemon (spice-vdagentd) needs this
  # per-session client to reach the desktop clipboard.
  systemd.user.services.spice-vdagent = {
    Unit = {
      Description = "SPICE session agent (clipboard sharing)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.spice-vdagent}/bin/spice-vdagent -x";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
