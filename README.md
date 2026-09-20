# nixdevbox

NixOS devbox for UTM on macOS. Structured to mirror `markov-g/gmv-nix-darwin`,
with `omarchy-nix` providing the Hyprland desktop.

```
/etc/nixos/
├── flake.nix                     # knobs: system, host, user, name, email
├── hardware-configuration.nix    # GENERATED, not in this repo
└── modules/
    ├── hardware-utm.nix          # virtio, spice, guest agent, 9p share
    ├── system.nix                # nix settings, base pkgs, nix-ld, fonts, avahi
    ├── users.nix                 # the `devel` account
    ├── ssh.nix                   # sshd + mosh
    ├── containers.nix            # rootless podman + docker compat + optional k3s
    ├── linuxbrew.nix             # OFF by default, read the header before enabling
    ├── dev/
    │   ├── c-cpp.nix  rust.nix  swift.nix  python.nix
    │   ├── dotnet.nix jvm.nix   cloud-native.nix  editors.nix
    └── home/
        ├── default.nix  shell.nix  git.nix
```

## Mapping from the macOS setup

| nix-darwin | nixdevbox |
|---|---|
| `nix-darwin.lib.darwinSystem` | `nixpkgs.lib.nixosSystem` |
| `modules/system.nix` | `modules/system.nix` + `modules/hardware-utm.nix` |
| `nix-homebrew` + `homebrew.nix` | `modules/linuxbrew.nix` (weaker, see below) |
| `modules/home.nix` | `modules/home/` |
| cask `jetbrains-toolbox` | `modules/dev/editors.nix` |
| cask `temurin` | `temurin-bin-21` in `modules/dev/jvm.nix` |
| `kylef/formulae/swiftenv` | `modules/dev/swift.nix` |
| `darwin-rebuild switch --flake` | `nixos-rebuild switch --flake` |

## UTM VM settings

- Architecture: ARM64 (aarch64), Virtualization (not Emulation) on Apple Silicon
- CPU: 4+ cores. Memory: 8 GB minimum, 12-16 GB if you run k3s or Rider
- Disk: 120 GB (the Nix store plus JetBrains IDEs plus .NET SDKs is not small)
- **Display: `virtio-ramfb-gl (GPU Supported)`** — Hyprland needs this
- Network: Shared. Forward host `2222` to guest `22` if you want a stable port
- Enable *Directory Share* (VirtFS) if you want `/mnt/mac`

## Install

1. Boot the NixOS minimal ISO, partition, `nixos-install` a bare system.
2. Reboot, then:

```bash
sudo nixos-generate-config --root /            # writes hardware-configuration.nix
sudo mkdir -p /etc/nixos
# copy this repo into /etc/nixos, keeping the generated hardware-configuration.nix
```

3. Edit `flake.nix`: `fullName`, `emailAddress`, and `system` if you are on Intel.
4. Edit `modules/users.nix`: paste your Mac's SSH public key.
5. Build:

```bash
sudo nixos-rebuild switch --flake /etc/nixos#nixdevbox
```

First build is long. Expect 45-90 minutes on a VM — JetBrains IDEs and the
.NET SDKs are large downloads, and anything not in the binary cache compiles.

6. Set a password and harden ssh:

```bash
passwd
# confirm `ssh devel@nixdevbox.local` works with your key, THEN
# set PasswordAuthentication = false in modules/ssh.nix and rebuild
```

## Day-to-day

```bash
rebuild          # nixos-rebuild switch, piped through nix-output-monitor
rebuild-test     # try it without making it the boot default
update           # nix flake update
rebuild-diff     # what changed between generations
```

## Per-project toolchains

The system-wide toolchains are for convenience and LSP. Real projects should
pin their own via `flake.nix` + `direnv`:

```bash
echo 'use flake' > .envrc && direnv allow
```

This is the main reason `nix-direnv` is installed.

## Known rough edges

**Hyprland in a VM.** If it fails to start, check `journalctl --user -u
hyprland` and confirm UTM is using a GL-capable display. `WLR_RENDERER_ALLOW_SOFTWARE=1`
is already set as a fallback. If you only ever use this box over SSH, you can
drop the omarchy module entirely and save a lot of build time.

**JetBrains Toolbox.** If the Toolbox package fails to build on aarch64, the
system still activates (it is guarded) and you fall back to `jetbrains.*` from
nixpkgs, which are patched for NixOS and more reliable anyway. IDEs installed
*by* Toolbox depend on `programs.nix-ld` to run.

**Swift.** Guarded the same way. If nixpkgs cannot provide it on your platform,
use the official Swift.org aarch64 Ubuntu tarball under nix-ld.

**Linuxbrew.** Off by default. No aarch64-linux bottles exist upstream, so
everything compiles from source and much of it assumes FHS paths. Prefer
nixpkgs. To enable:

```nix
gmv.linuxbrew = {
  enable = true;
  brews = [ "some-formula-nixpkgs-lacks" ];
};
```

The `PATH` is deliberately ordered so nixpkgs wins any name collision.

**kind + podman.** `KIND_EXPERIMENTAL_PROVIDER=podman` is set. Rootless kind
occasionally needs cgroup v2 delegation; if a cluster fails to come up, the
quickest diagnostic is `podman info --format '{{.Host.CgroupsVersion}}'`.
