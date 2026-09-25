# AGENTS.md

## Project

This repository defines a NixOS development VM for UTM on Apple Silicon. The
flake builds the `nixdevbox` configuration for `aarch64-linux` and includes
Home Manager for the `devel` user.

## Configuration Layout

- `flake.nix` defines the system, host, and user knobs and imports the modules.
- `hardware-configuration.nix` is generated and specific to the current VM.
  Do not copy it to another machine; generate hardware configuration for that
  machine instead.
- `modules/system.nix` contains base Nix settings, packages, and services.
- `modules/desktop.nix` configures GNOME, audio, printing, and Firefox.
- `modules/hardware-utm.nix` contains UTM/QEMU guest settings.
- `modules/users.nix` and `modules/ssh.nix` configure the login account and
  SSH services.
- `modules/dev/` contains system-wide development toolchains.
- `modules/home/` contains Home Manager settings for the user's shell, Git,
  SSH client, and dotfiles.
- `modules/containers.nix` configures rootless Podman; k3s is disabled by
  default.
- `modules/linuxbrew.nix` is optional and disabled by default.

## Editing Guidance

- Put system-wide tools in `modules/dev/` and user-specific programs or
  dotfiles in `modules/home/`.
- Keep `system.stateVersion` in `modules/system.nix` unchanged after initial
  installation.
- Treat `hardware-configuration.nix` as generated, machine-specific input.
- Do not put private keys, tokens, or plaintext credentials in Nix files.
  Nix store contents are world-readable. The default initial password in
  `modules/users.nix` is for a disposable lab VM and must be changed before
  using the system with sensitive data.
- The target checkout at `/etc/nixos` is root-owned. Do not change `.git`
  ownership to bypass permissions. Follow the README's GitHub-over-443 pull
  procedure; `sudo git` does not use the user's Home Manager SSH config.
- Read module comments before enabling optional components, especially
  Linuxbrew and k3s.

## Verification

There is no dedicated test suite in this repository. For Nix changes:

```sh
nixpkgs-fmt --check
nix flake check
nix eval .#nixosConfigurations.nixdevbox.config.system.build.toplevel.drvPath
```

`nixos-rebuild switch --flake /etc/nixos#nixdevbox` activates the configuration
on the machine. Treat it as a deployment command, not a validation-only check.
