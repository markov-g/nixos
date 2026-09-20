{ pkgs, ... }:

# AI coding agents. On the Mac these come from Homebrew casks; nixpkgs
# packages them directly on Linux.
{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode

    # Several of these shell out to node for MCP servers and plugins.
    nodejs_22

    # sops toolchain, staged for the secrets migration
    sops
    age
    ssh-to-age
  ];
}
