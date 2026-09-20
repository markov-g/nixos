{ pkgs, ... }:

let
  # rust-overlay gives a pinned, cached stable toolchain. If a project ships a
  # rust-toolchain.toml, use a per-project devShell with
  # `pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml` instead.
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" "llvm-tools" ];
    targets = [
      "aarch64-unknown-linux-gnu"
      "aarch64-unknown-linux-musl"
      "wasm32-unknown-unknown"
    ];
  };
in
{
  environment.systemPackages = with pkgs; [
    rustToolchain

    # cargo ecosystem
    cargo-edit
    cargo-watch
    cargo-nextest
    cargo-audit
    cargo-deny
    cargo-expand
    cargo-outdated
    cargo-bloat
    cargo-flamegraph
    cargo-generate
    cargo-udeps
    bacon
    sccache

    # ffi / bindings
    rustPlatform.bindgenHook
    cargo-cross # needs podman/docker, wired up in containers.nix
  ];

  environment.variables = {
    # mold linker by default - big win on a CPU-limited VM
    RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
    RUSTC_WRAPPER = "${pkgs.sccache}/bin/sccache";
    CARGO_INCREMENTAL = "0"; # incremental + sccache fight each other
  };
}
