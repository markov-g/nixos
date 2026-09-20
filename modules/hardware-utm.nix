{ config, lib, pkgs, ... }:

# Everything specific to running as a UTM / QEMU guest.
# This does NOT replace hardware-configuration.nix - it sits on top of it.
#
# READ THIS FIRST: UTM has two backends and they are not interchangeable.
#
#   QEMU backend  ("Virtualize" with QEMU, or "Emulate")
#       -> SPICE channel exists. qemuGuest + spice-vdagentd + spice-webdavd
#          all apply. This module assumes this backend.
#
#   Apple Virtualization backend (the "Use Apple Virtualization" checkbox)
#       -> No SPICE channel and no QEMU guest agent socket at all. These
#          services will start and then sit there finding no virtio-serial
#          port to talk to. Clipboard and folder sharing go through
#          Apple's own virtio-fs / console plumbing instead, and dynamic
#          resolution is not available. If you tick that box, expect the
#          three services below to be inert rather than broken.
#
# Check which one you are on: `ls /dev/virtio-ports/` should list
# com.redhat.spice.0 on the QEMU backend.

{
  # ---------------------------------------------------------------------
  # Boot. UTM on Apple Silicon boots aarch64 UEFI.
  # ---------------------------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "virtio_gpu"
    "9p"
    "9pnet_virtio"
    "xhci_pci"
    "usbhid"
    "sr_mod"
  ];
  boot.kernelModules = [ "virtio_gpu" "virtiofs" ];

  # Kernel of the release channel is fine; uncomment for a newer one.
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  # ---------------------------------------------------------------------
  # Guest integration
  # ---------------------------------------------------------------------
  # NOTE: the option is `spice-vdagentd` (the daemon), NOT `spice-vdagent`.
  # `services.spice-vdagent.enable` does not exist in NixOS and will fail
  # evaluation with "The option does not exist".
  services.qemuGuest.enable = true; # host-initiated shutdown/reboot, fs-freeze
  services.spice-vdagentd.enable = true; # clipboard sharing, display resize
  services.spice-webdavd.enable = true; # UTM "shared directory" over WebDAV

  # Dynamic resolution on X11 sessions. Harmless to leave on; it does nothing
  # for Wayland, where the compositor handles virtio-gpu hotplug itself.
  services.spice-autorandr.enable = true;

  # Time sync. The QEMU guest agent only corrects the clock across
  # suspend/resume; it is not a time source. Closing the MacBook lid parks the
  # VM and the guest clock drifts, so run NTP as well.
  services.timesyncd.enable = true;
  services.timesyncd.servers = [
    "0.nixos.pool.ntp.org"
    "1.nixos.pool.ntp.org"
    "2.nixos.pool.ntp.org"
    "3.nixos.pool.ntp.org"
  ];

  # ---------------------------------------------------------------------
  # Graphics. Hyprland needs a DRM device + GL.
  # In UTM set Display = "virtio-ramfb-gl (GPU Supported)".
  # ---------------------------------------------------------------------
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      libva
      virglrenderer
    ];
  };

  # virgl is the software/paravirt GL path. Without this Hyprland may refuse
  # to start on some UTM display backends.
  environment.sessionVariables = {
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # ---------------------------------------------------------------------
  # Shared folder from macOS.
  # UTM VirtFS exposes a 9p mount with tag "share".
  # Enable the UTM setting first, then uncomment.
  # ---------------------------------------------------------------------
  # fileSystems."/mnt/mac" = {
  #   device = "share";
  #   fsType = "9p";
  #   options = [
  #     "trans=virtio"
  #     "version=9p2000.L"
  #     "msize=512000"
  #     "cache=mmap"
  #     "nofail"
  #     "x-systemd.automount"
  #   ];
  # };

  # ---------------------------------------------------------------------
  # VM ergonomics
  # ---------------------------------------------------------------------
  # Disk is thin-provisioned; trim it back to the host.
  services.fstrim.enable = true;

  # Give yourself swap so a `cargo build -j` or a JVM doesn't OOM the guest.
  swapDevices = lib.mkDefault [{
    device = "/var/lib/swapfile";
    size = 8 * 1024; # MiB
  }];

  # Build parallelism - tune to the vCPUs you gave the VM.
  nix.settings.max-jobs = lib.mkDefault 4;
  nix.settings.cores = lib.mkDefault 0; # 0 = all available
}
