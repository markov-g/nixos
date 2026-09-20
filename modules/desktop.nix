{ config, lib, pkgs, ... }:

# Carried over from the stock configuration.nix that got this VM booting.

{
  # Audio. Omarchy/Hyprland does not set this up for you.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;
  programs.firefox.enable = true;

  # GNOME kept as a FALLBACK SESSION. Hyprland in UTM depends on a
  # GL-capable virtio display; if it fails you would otherwise have no
  # graphical way back in. Pick the session at the GDM login screen.
  #
  # If omarchy-nix brings its own display manager this will fail to
  # evaluate. In that case comment these two lines out.
  services.displayManager.gdm.enable = lib.mkDefault true;
  services.desktopManager.gnome.enable = lib.mkDefault true;

  # GNOME ships gcr-ssh-agent, which conflicts with programs.ssh.startAgent
  # in modules/ssh.nix. Only one SSH agent may be enabled. Keep the plain
  # one - it behaves the same in a terminal and over SSH.
  services.gnome.gcr-ssh-agent.enable = false;
}
