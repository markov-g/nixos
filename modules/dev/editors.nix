{ pkgs, lib, ... }:

# JetBrains on NixOS, honestly:
#
#   Path A - jetbrains-toolbox (what you asked for). The launcher itself is
#            packaged. The IDEs it downloads are generic-Linux FHS binaries
#            that expect /lib64/ld-linux-*.so. programs.nix-ld (system.nix)
#            is what lets them start at all. [Unverified] whether the
#            nixpkgs derivation currently builds on aarch64-linux.
#
#   Path B - nixpkgs-native IDEs. Patched for NixOS, reproducible, and they
#            just work. Downside: version is whatever the channel has.
#
# Both are enabled. Use Toolbox for updates-on-your-schedule, fall back to
# Path B the moment Toolbox misbehaves.

let
  toolbox =
    let t = builtins.tryEval (pkgs.jetbrains-toolbox.outPath or null);
    in lib.optional (t.success && t.value != null) pkgs.jetbrains-toolbox;
in
{
  warnings = lib.optional (toolbox == [ ])
    "jetbrains-toolbox is unavailable on this platform in the pinned nixpkgs; only the native jetbrains.* IDEs were installed.";

  environment.systemPackages =
    toolbox
    ++ (with pkgs; [
      # ---- Path B: native, patched IDEs (comment out what you don't want) ----
      jetbrains.idea # Java / Kotlin
      jetbrains.clion # C / C++ / Rust
      jetbrains.pycharm # Python
      jetbrains.rider # .NET
      # jetbrains.rust-rover
      # jetbrains.datagrip

      # ---- Toolbox runtime deps ----
      fuse3
      libsecret # credential storage
      jetbrains.jdk # JBR, used by remote dev backends

      # ---- other editors ----
      vscode
      neovim
      helix

      # ---- remote dev from the Mac ----
      # JetBrains Gateway connects over SSH and drops a backend in
      # ~/.cache/JetBrains - that backend needs nix-ld too.
    ]);

  # Toolbox writes AppImages into ~/.local/share/JetBrains and needs
  # user-space FUSE mounts to run them.
  programs.fuse.userAllowOther = true;

  # IDEs watch a LOT of files. Default inotify limits will bite you on any
  # non-trivial monorepo.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 1024;
  };
}
