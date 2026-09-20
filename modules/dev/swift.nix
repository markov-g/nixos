{ pkgs, lib, ... }:

# [Unverified] Swift on aarch64-linux in nixpkgs has historically been the
# least reliable of these toolchains - upstream Swift only added first-class
# aarch64-linux support relatively late and the nixpkgs derivation has been
# marked broken on that platform at various points.
#
# So: we probe for it instead of hard-failing the whole system build.
# If `swift` is unavailable, `nixos-rebuild` still succeeds and you get a
# warning. Check availability yourself with:
#     nix eval --raw nixpkgs#swift.meta.platforms
#     nix build nixpkgs#swift --dry-run

let
  swiftAvailable =
    let t = builtins.tryEval (pkgs.swift.outPath or null);
    in t.success && t.value != null;

  swiftPkgs = lib.optionals swiftAvailable (with pkgs; [
    swift
    swiftpm
    swift-format
    sourcekit-lsp
  ]);
in
{
  warnings = lib.optional (!swiftAvailable)
    "swift is not available for this platform in the pinned nixpkgs; Swift tooling was skipped. See modules/dev/swift.nix.";

  environment.systemPackages = swiftPkgs ++ (with pkgs; [
    # Swift on Linux links against these regardless of how you get the compiler.
    libxml2
    libuuid
    icu
    curl
    sqlite
  ]);

  # Fallback if the nixpkgs derivation is unusable: run the official
  # Swift.org aarch64 Ubuntu tarball under nix-ld. Unpack it to
  # ~/toolchains/swift and add ~/toolchains/swift/usr/bin to PATH.
  # That path relies on programs.nix-ld from modules/system.nix.
}
