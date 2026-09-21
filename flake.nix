{
  description = "GMv's NixOS devbox (UTM/Apple Silicon) - NixOS + Home-Manager";

  inputs = {
    # Pinned to the release channel matching system.stateVersion (26.05).
    # Unstable is available separately as `pkgs.unstable.*` via an overlay.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Read-only source for shared Mac dotfiles and tool configuration.
    gmv-mac = {
      url = "github:markov-g/gmv-nix-darwin/mac-mini";
      flake = false;
    };

    # Pinned Spacemacs source; Home Manager materializes it into a writable
    # runtime directory because Emacs and its package manager write there.
    spacemacs = {
      url = "github:syl20bnr/spacemacs/develop";
      flake = false;
    };

    # Rust toolchain channels (stable/beta/nightly, per-project via rust-toolchain.toml)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Omarchy (Hyprland desktop) is deliberately NOT an input.
    # GNOME from modules/desktop.nix is the desktop instead.
    # To bring it back, see flake.nix.with-omarchy.
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , home-manager
    , rust-overlay
    , ...
    }@inputs:
    let
      # --------------------------------------------------------------------
      # Knobs. Change these, nothing else.
      # --------------------------------------------------------------------
      system = "aarch64-linux"; # "x86_64-linux" on Intel Macs
      host = "nixdevbox";
      user = "devel";

      # Expose nixpkgs-unstable as pkgs.unstable.<pkg>
      unstableOverlay = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit (prev) system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations.${host} = nixpkgs.lib.nixosSystem {
        inherit system;

        # Make `user`, `host` and all inputs available to every module.
        specialArgs = { inherit user host inputs; };

        modules = [
          # ---------- overlays / nixpkgs policy ----------
          ({ ... }: {
            nixpkgs.overlays = [
              unstableOverlay
              rust-overlay.overlays.default
            ];
            nixpkgs.config.allowUnfree = true;
          })

          # ---------- machine ----------
          ./hardware-configuration.nix
          ./modules/hardware-utm.nix
          ./modules/system.nix
          ./modules/users.nix
          ./modules/ssh.nix
          ./modules/desktop.nix

          # ---------- dev toolchains (system-wide) ----------
          ./modules/dev

          # ---------- containers / kubernetes ----------
          ./modules/containers.nix

          # ---------- optional: Homebrew-on-Linux escape hatch (off) ----------
          ./modules/linuxbrew.nix

          # ---------- Home-Manager ----------
          home-manager.nixosModules.home-manager
          ({ ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-bak";
            home-manager.extraSpecialArgs = { inherit user host inputs; };
            home-manager.users.${user} = {
              imports = [ ./modules/home ];
            };
          })
        ];
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
    };
}
