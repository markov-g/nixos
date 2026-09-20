{ pkgs, ... }:

let
  # Side-by-side SDKs so `global.json` pinning works across projects.
  #dotnet = with pkgs.dotnetCorePackages; combinePackages [
  #  sdk_9_0
  #  sdk_10_0
  #];
  dotnet = pkgs.dotnetCorePackages.sdk_9_0;
in
{
  environment.systemPackages = with pkgs; [
    dotnet
    mono
    msbuild
    omnisharp-roslyn # LSP
    netcoredbg # debugger (used by VS Code / Rider fallback)
    powershell
  ];

  environment.variables = {
    DOTNET_ROOT = "${dotnet}/share/dotnet";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
    # The SDK tries to write to a read-only store path otherwise.
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE = "1";
  };

  environment.sessionVariables.PATH = [ "$HOME/.dotnet/tools" ];
}
