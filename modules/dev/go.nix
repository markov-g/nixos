{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    go
    gopls
    delve
  ];

  environment.sessionVariables = {
    GOPATH = "$HOME/go";
    GOBIN = "$HOME/go/bin";
  };

  environment.sessionVariables.PATH = [ "$HOME/go/bin" ];
}
