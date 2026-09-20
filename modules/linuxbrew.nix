{ config, lib, pkgs, user, ... }:

# ============================================================================
# Linuxbrew, orchestrated by Nix.
#
# BE CLEAR ABOUT WHAT THIS IS. On macOS, nix-homebrew genuinely manages
# Homebrew: it owns the prefix, pins taps as flake inputs, and `brew bundle`
# reconciles state on every activation. There is no Linux equivalent.
#
# What this module does instead:
#   1. Creates /home/linuxbrew/.linuxbrew with the right ownership (declarative)
#   2. Clones/updates brew there on activation (imperative, network-dependent)
#   3. Runs `brew bundle --cleanup` against a Nix-generated Brewfile so the
#      *package list* is declarative even though the mechanism is not
#   4. Wires shellenv into the user's shell
#
# Two problems you should weigh before using it:
#   - Homebrew publishes NO aarch64-linux bottles. Every formula compiles from
#     source. On a VM that is slow, and many formulae will simply fail.
#   - Brew binaries assume FHS. programs.nix-ld helps; it is not a guarantee.
#
# My actual recommendation: leave `enable = false` and get everything from
# nixpkgs. Turn it on only for a specific formula nixpkgs genuinely lacks.
# ============================================================================

let
  cfg = config.gmv.linuxbrew;
  brewPrefix = "/home/linuxbrew/.linuxbrew";

  brewfile = pkgs.writeText "Brewfile" (
    lib.concatMapStringsSep "\n" (t: ''tap "${t}"'') cfg.taps
    + "\n"
    + lib.concatMapStringsSep "\n" (b: ''brew "${b}"'') cfg.brews
    + "\n"
  );
in
{
  options.gmv.linuxbrew = {
    enable = lib.mkEnableOption "Nix-orchestrated Linuxbrew";

    taps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "sdkman/tap" ];
    };

    brews = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Formulae to reconcile. Anything not listed gets removed.";
    };
  };

  config = lib.mkMerge [
    # Default to OFF. See the header.
    { gmv.linuxbrew.enable = lib.mkDefault false; }

    (lib.mkIf cfg.enable {
      # ---- 1. the prefix, declaratively ----
      users.groups.linuxbrew = { };
      systemd.tmpfiles.rules = [
        "d /home/linuxbrew 0755 ${user} linuxbrew - -"
        "d ${brewPrefix} 0755 ${user} linuxbrew - -"
      ];

      # ---- 2. brew's own build dependencies ----
      environment.systemPackages = with pkgs; [
        gcc
        gnumake
        curl
        git
        file
        procps
        which
        patchelf
      ];

      # ---- 3. bootstrap + reconcile on activation ----
      system.activationScripts.linuxbrew = {
        deps = [ "users" "groups" ];
        text = ''
          set -eu
          PATH=${lib.makeBinPath (with pkgs; [ git curl coreutils bash gnused gnugrep ])}:$PATH

          if [ ! -d ${brewPrefix}/Homebrew ]; then
            echo "[linuxbrew] bootstrapping into ${brewPrefix}"
            ${pkgs.su}/bin/su - ${user} -c \
              "${pkgs.git}/bin/git clone --depth=1 https://github.com/Homebrew/brew ${brewPrefix}/Homebrew" || \
              echo "[linuxbrew] clone failed (offline?); skipping"
            mkdir -p ${brewPrefix}/bin
            ln -sfn ${brewPrefix}/Homebrew/bin/brew ${brewPrefix}/bin/brew
            chown -R ${user}:linuxbrew /home/linuxbrew
          fi

          if [ -x ${brewPrefix}/bin/brew ]; then
            ${pkgs.su}/bin/su - ${user} -c \
              "HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 \
               ${brewPrefix}/bin/brew bundle --file=${brewfile} --cleanup" || \
              echo "[linuxbrew] brew bundle failed; continuing so the system still activates"
          fi
        '';
      };

      # ---- 4. shell wiring ----
      environment.variables = {
        HOMEBREW_PREFIX = brewPrefix;
        HOMEBREW_CELLAR = "${brewPrefix}/Cellar";
        HOMEBREW_REPOSITORY = "${brewPrefix}/Homebrew";
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_AUTO_UPDATE = "1";
      };

      # Deliberately appended AFTER the Nix profile, so nixpkgs always wins
      # a name collision. This is the single most important line here.
      environment.extraInit = ''
        if [ -d ${brewPrefix}/bin ]; then
          export PATH="$PATH:${brewPrefix}/bin:${brewPrefix}/sbin"
          export MANPATH="''${MANPATH:-}:${brewPrefix}/share/man"
        fi
      '';
    })
  ];
}
