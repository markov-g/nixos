{ config, lib, pkgs, ... }:

# NOTE ON CONFLICTS: omarchy-nix's home-manager module also configures shell
# bits. Home-Manager will error on duplicate definitions rather than silently
# picking one. Everything here that omarchy might also set is wrapped in
# lib.mkDefault; if you still get "option defined multiple times", change that
# specific option to lib.mkForce.

{
  programs.zsh = {
    enable = true;
    enableCompletion = lib.mkDefault true;
    autosuggestion.enable = lib.mkDefault true;
    syntaxHighlighting.enable = lib.mkDefault true;

    history = {
      size = 100000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    # Replaces the antigen setup from your Mac .zshrc with HM-managed plugins.
    oh-my-zsh = {
      enable = lib.mkDefault true;
      plugins = [ "git" "sudo" "kubectl" "podman" "rust" "gradle" "dotnet" ];
      theme = ""; # starship renders the prompt
    };

    shellAliases = {
      # eza (parity with your brews)
      ls = "eza --group-directories-first";
      ll = "eza -lh --git --group-directories-first";
      la = "eza -lah --git --group-directories-first";
      lt = "eza --tree --level=2";

      cat = "bat --paging=never";
      grep = "rg";

      # nix
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixdevbox |& nom";
      rebuild-test = "sudo nixos-rebuild test --flake /etc/nixos#nixdevbox";
      rebuild-diff = "nvd diff /run/current-system result";
      update = "nix flake update --flake /etc/nixos";
      gc = "sudo nix-collect-garbage -d";

      # k8s
      k = "kubecolor";
      kx = "kubectx";
      kn = "kubens";

      # containers
      d = "podman";
      dc = "podman-compose";

      # Spacemacs runs as the Nix-provided Emacs configuration.
      spacemacs = "emacs";
    };

    initContent = lib.mkOrder 1000 ''
      # keybindings
      bindkey -e
      bindkey '^[[A' history-substring-search-up 2>/dev/null || true

      # fzf-driven cd
      eval "$(zoxide init zsh)" 2>/dev/null || true

      # kubectl completion through the kubecolor alias
      compdef kubecolor=kubectl 2>/dev/null || true
    '';
  };

  programs.starship = {
    enable = lib.mkDefault true;
    settings = {
      add_newline = false;
      kubernetes.disabled = false;
      container.disabled = false;
      nix_shell.symbol = " ";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  programs.fzf = {
    enable = lib.mkDefault true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
  };

  programs.bat.enable = lib.mkDefault true;
  programs.eza.enable = lib.mkDefault true;
  programs.zoxide.enable = lib.mkDefault true;
  programs.btop.enable = lib.mkDefault true;

  programs.tmux = {
    enable = lib.mkDefault true;
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    escapeTime = 10;
    historyLimit = 50000;
    baseIndex = 1;
  };
}
