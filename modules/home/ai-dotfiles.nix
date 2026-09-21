{ lib, pkgs, inputs, user, ... }:

let
  macDotfiles = "${inputs.gmv-mac}/modules/dotfiles/macos";

  collectFiles = root: prefix:
    let
      entries = builtins.readDir root;
    in
    lib.concatLists (lib.mapAttrsToList
      (name: type:
        let
          relative = if prefix == "" then name else "${prefix}/${name}";
          source = "${root}/${name}";
        in
        if type == "directory" then
          collectFiles source relative
        else if type == "regular" || type == "symlink" then
          [ { inherit relative source; } ]
        else
          [ ])
      entries);

  filesFrom = paths:
    lib.concatLists (map
      (path: collectFiles "${macDotfiles}/${path}" path)
      paths);

  sharedFiles = filesFrom [
    ".claude"
    ".codex/hooks"
    ".codex/skills"
    ".config/opencode/themes"
    ".config/mcphub"
  ] ++ [
    {
      relative = ".codex/AGENTS.md";
      source = "${macDotfiles}/.codex/AGENTS.md";
    }
    {
      relative = ".config/opencode/dcp.jsonc";
      source = "${macDotfiles}/.config/opencode/dcp.jsonc";
    }
  ];

  nvimFiles = filesFrom [ ".config/nvim" ];

  nvimLspConfig = builtins.replaceStrings
    [ "cmd       = { \"/usr/bin/xcrun\", \"sourcekit-lsp\" }," ]
    [ "cmd       = { \"sourcekit-lsp\" }," ]
    (builtins.readFile "${macDotfiles}/.config/nvim/lua/plugins/lsp.lua");

  nvimHomeFiles = lib.listToAttrs (map
    (file: lib.nameValuePair file.relative { source = file.source; })
    (builtins.filter
      (file: file.relative != ".config/nvim/lua/plugins/lsp.lua")
      nvimFiles));

  codexConfig = builtins.replaceStrings
    [ "/Users/devel/git-repos/workspace/claude-cs" ]
    [ "/home/${user}/git-repos/workspace/claude-cs" ]
    (builtins.readFile "${macDotfiles}/.codex/config.toml");

  opencodeSlimConfig = builtins.replaceStrings
    [ "\"type\": \"herdr\"" ]
    [ "\"type\": \"tmux\"" ]
    (builtins.readFile "${macDotfiles}/.config/opencode/oh-my-opencode-slim.jsonc");

  sharedHomeFiles = lib.listToAttrs (map
    (file: lib.nameValuePair file.relative { source = file.source; })
    sharedFiles);
in
{
  home.file = sharedHomeFiles // nvimHomeFiles // {
    # Adapt the Mac config's one absolute trusted-project path to Linux while
    # preserving the rest of the file as the shared source of truth.
    ".codex/config.toml".text = codexConfig;

    # Herdr is Mac-specific; oh-my-opencode-slim supports tmux on Linux.
    ".config/opencode/oh-my-opencode-slim.jsonc".text = opencodeSlimConfig;

    # Keep the current provider/model configuration shared with the Mac.
    ".config/opencode/opencode.jsonc".source =
      "${macDotfiles}/.config/opencode/opencode.jsonc";

    # The shared file is otherwise identical, but Mac Swift uses xcrun.
    ".config/nvim/lua/plugins/lsp.lua".text = nvimLspConfig;
  };

  home.sessionVariables.NVIM_DEBUGPY_PYTHON =
    "${pkgs.python313.withPackages (ps: [ ps.debugpy ])}/bin/python";
}
