{ config, lib, pkgs, user, ... }:

{
  # ---------------------------------------------------------------------
  # Podman, rootless, with a Docker-compatible socket so that kind,
  # testcontainers, skaffold and every tool that hardcodes DOCKER_HOST works.
  # ---------------------------------------------------------------------
  virtualisation.containers.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # provides /run/podman/podman.sock + `docker` alias
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--all" ];
    };
  };

  virtualisation.containers.registries.search = [
    "docker.io"
    "quay.io"
    "ghcr.io"
    "registry.k8s.io"
  ];

  # NOTE: a dynamic attribute like ${user} can only be bound ONCE per
  # attrset, so everything about this user goes in a single block.
  users.users.${user} = {
    # Rootless podman needs subuid/subgid ranges.
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
    # Keep the user's containers running when they are not logged in
    # (so a kind cluster survives closing the ssh session).
    linger = true;
  };

  environment.systemPackages = with pkgs; [
    podman
    podman-compose
    podman-tui
    buildah
    crun
    conmon
    slirp4netns
    fuse-overlayfs
    netavark
    aardvark-dns
    lazydocker
    docker-buildx
    docker-compose # works against the podman socket
  ];

  environment.variables = {
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
    DOCKER_BUILDKIT = "1";
  };

  # ---------------------------------------------------------------------
  # Optional: a real single-node Kubernetes.
  #
  #   (a) kind / minikube on top of podman  - ephemeral, nothing to enable
  #   (b) k3s as a systemd service          - always-on, survives reboots
  #
  # (b) is off by default because it holds ~700MB RSS permanently.
  # ---------------------------------------------------------------------
  services.k3s = {
    enable = lib.mkDefault false;
    role = "server";
    extraFlags = toString [
      "--write-kubeconfig-mode=0644"
      "--disable=traefik"
    ];
  };

  networking.firewall.allowedTCPPorts = lib.mkIf config.services.k3s.enable [
    6443 # kube api
    10250 # kubelet
  ];

  boot.kernelModules = lib.mkIf config.services.k3s.enable [ "br_netfilter" "overlay" ];
}
