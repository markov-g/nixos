# nixdevbox

NixOS development VM for UTM on macOS. It uses NixOS and Home Manager, with
GNOME as the configured desktop and development toolchains managed by Nix.

```
/etc/nixos/
|-- flake.nix                    # machine knobs: system, host, user
|-- flake.lock                   # pinned flake inputs
|-- hardware-configuration.nix   # generated for this VM; machine-specific
`-- modules/
    |-- hardware-utm.nix         # UTM/QEMU guest integration
    |-- system.nix               # Nix settings, base packages, fonts, services
    |-- desktop.nix              # GNOME, audio, printing, Firefox
    |-- users.nix                # the configured login account
    |-- ssh.nix                  # OpenSSH server and mosh
    |-- containers.nix           # rootless Podman; optional k3s
    |-- linuxbrew.nix            # optional; disabled by default
    |-- dev/                     # system-wide development toolchains
    `-- home/                    # Home Manager shell, Git, and dotfiles
```

## Mapping from the macOS setup

| nix-darwin | nixdevbox |
|---|---|
| `nix-darwin.lib.darwinSystem` | `nixpkgs.lib.nixosSystem` |
| `modules/system.nix` | `modules/system.nix` + `modules/hardware-utm.nix` |
| `nix-homebrew` + `homebrew.nix` | `modules/linuxbrew.nix` (optional, see below) |
| `modules/home.nix` | `modules/home/` |
| cask `jetbrains-toolbox` | `modules/dev/editors.nix` |
| cask `temurin` | `temurin-bin-21` in `modules/dev/jvm.nix` |
| `kylef/formulae/swiftenv` | `modules/dev/swift.nix` |
| `darwin-rebuild switch --flake` | `nixos-rebuild switch --flake` |

## UTM VM settings

- Architecture: ARM64 (`aarch64`) on Apple Silicon.
- The UTM module assumes the QEMU backend. The Apple Virtualization backend
  does not provide the SPICE guest channel used by some configured services.
- The VM configuration enables virtio graphics and SPICE guest integration.
- 4 or more vCPUs and 8 GB RAM are a practical starting point; allocate more
  memory for large IDEs or Kubernetes workloads.
- A 120 GB disk leaves room for the Nix store, IDEs, and SDKs.
- Use shared networking. Forward host port 2222 to guest port 22 for a stable
  SSH port if needed.
- The `/mnt/mac` 9p mount is commented out in `modules/hardware-utm.nix`.
  Enable UTM directory sharing and uncomment that mount to use it.

## Install

1. Install a base NixOS system and generate hardware configuration for the VM.
2. Place this repository in `/etc/nixos`, preserving the generated
   `hardware-configuration.nix`. The file in this checkout belongs to its
   current VM and should not be reused for different hardware.
3. Review the machine settings:

   - Set `system`, `host`, and `user` in `flake.nix` for the target machine.
   - Set the login public key in `modules/users.nix` and the timezone in
     `modules/system.nix` as needed.
   - `modules/users.nix` currently has a default initial password of
     `changeme`. Change it immediately after first boot; Nix store contents are
     world-readable, so do not use a plaintext initial password for a system
     that holds sensitive data.
4. Build and activate:

   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#nixdevbox
   ```

The first build can take a while because IDEs and SDKs are large and uncached
packages may need to compile for `aarch64-linux`.

5. Set a personal password and, after confirming key-based SSH access, consider
   disabling password authentication in `modules/ssh.nix`:

   ```bash
   passwd
   # confirm `ssh devel@nixdevbox.local` works with your key, THEN
   # set PasswordAuthentication = false in modules/ssh.nix and rebuild
   ```

## Updating this checkout

The live checkout at `/etc/nixos` is root-owned. Keep it that way; do not
change `.git` ownership to work around write-permission errors. A normal-user
SSH test uses the user's key and SSH config, while `sudo git` runs SSH as root.
For GitHub, use the user's key explicitly and connect over port 443:

```bash
cd /etc/nixos
sudo git -c core.sshCommand="ssh -i $HOME/.ssh/id_rsa -o IdentitiesOnly=yes -o HostName=ssh.github.com -p 443" pull \
  && sudo nixos-rebuild switch --flake /etc/nixos#nixdevbox
```

Keep the double quotes around `core.sshCommand`: the user's shell expands
`$HOME` before `sudo` starts Git. The GitHub key and port settings for the
normal user are managed in `modules/home/git.nix`; root does not read that
Home Manager SSH config.

To update locked flake inputs intentionally, review the resulting
`flake.lock` change and rebuild:

```bash
sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#nixdevbox
```

This is separate from pulling repository changes. The `update` shell alias is
defined without `sudo`; use the command above for this root-owned checkout.
For ordinary configuration changes, the `rebuild` and `rebuild-test` aliases
are also available in `modules/home/shell.nix`.

## Per-project toolchains

The system-wide toolchains are for convenience and LSP. Real projects should
pin their own via `flake.nix` + `direnv`:

```bash
echo 'use flake' > .envrc && direnv allow
```

This is the main reason `nix-direnv` is installed.

## Optional components and caveats

**Desktop.** The flake currently configures GNOME in `modules/desktop.nix`.
Omarchy and Hyprland are not imported by this configuration.

**JetBrains Toolbox.** `modules/dev/editors.nix` includes Toolbox only when the
package is available. Nixpkgs-native JetBrains IDEs are installed as a
fallback. IDEs downloaded by Toolbox rely on `programs.nix-ld`.

**Swift.** `modules/dev/swift.nix` checks package availability and skips Swift
tooling with a warning when it is unavailable for the pinned platform.

**Linuxbrew.** Disabled by default. On `aarch64-linux`, formulae may compile
from source and some expect FHS paths. Prefer nixpkgs. To enable:

```nix
gmv.linuxbrew = {
  enable = true;
  brews = [ "some-formula-nixpkgs-lacks" ];
};
```

The `PATH` is deliberately ordered so nixpkgs wins any name collision.

**Kubernetes.** Rootless Podman is enabled. The system k3s service is disabled
by default because it keeps a server running and uses additional memory.
