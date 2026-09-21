{ lib, pkgs, inputs, ... }:

{
  home.packages = [ pkgs.emacs-pgtk ];

  # Spacemacs itself and its package cache need a writable home directory.
  # The source is still pinned by flake.lock and refreshed on each activation.
  home.activation.syncSpacemacs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.emacs.d"
    mkdir -p "$target"
    ${pkgs.rsync}/bin/rsync -a --delete \
      --exclude='.cache' \
      --exclude='elpa' \
      --exclude='server' \
      --exclude='.git' \
      "${inputs.spacemacs}/" "$target/"
  '';

  home.file.".spacemacs".text = ''
    (defun dotspacemacs/layers ()
      (setq-default
       dotspacemacs-configuration-layers
       '(
         auto-completion
         git
         lsp
         markdown
         org
         python
         go
         rust
         c-c++
         java
         (kotlin :variables kotlin-backend 'lsp)
         (swift :variables
                swift-backend 'lsp
                swift-lsp-executable-path "sourcekit-lsp")
         (csharp :variables csharp-backend 'lsp)
         (zig :variables
               lsp-zig-zls-executable "zls"
               lsp-zig-zig-exe-path "zig")
         shell
         syntax-checking
         version-control)
       dotspacemacs-additional-packages '(gptel vterm)))

    (defun dotspacemacs/init ()
      (setq-default
       dotspacemacs-editing-style 'vim
       dotspacemacs-startup-banner 'official
       dotspacemacs-themes '(spacemacs-dark spacemacs-light)
       dotspacemacs-default-font '("FiraCode Nerd Font" :size 13 :weight normal :width normal)))

    (defun dotspacemacs/user-init ()
      ;; The language servers and compilers are provided by NixOS modules.
      (setq lsp-clients-kotlin-server-executable "kotlin-language-server"))

    (defun dotspacemacs/user-config ()
      (defun gmv/open-opencode ()
        (interactive)
        (vterm)
        (vterm-send-string "opencode")
        (vterm-send-return))

      ;; gptel is available for direct model use; OpenCode is the main
      ;; agent workflow and gets a dedicated terminal shortcut.
      (global-set-key (kbd "C-c a") #'gptel)
      (global-set-key (kbd "C-c o") #'gmv/open-opencode))
  '';
}
