{ pkgs, lib, ... }:

let
  defaultJdk = pkgs.temurin-bin-21; # matches the `temurin` cask on your Mac
in
{
  environment.systemPackages = with pkgs; [
    # JDKs - 21 is default, others available for cross-version testing
    defaultJdk
    temurin-bin-17

    # build
    gradle
    maven
    ant

    # Kotlin
    kotlin
    kotlin-language-server
    ktlint
    ktfmt

    # Java tooling
    jdt-language-server
    google-java-format
    checkstyle
    visualvm
    jmeter

  ];

  programs.java = {
    enable = true;
    package = defaultJdk;
  };

  environment.variables = {
    JAVA_HOME = "${defaultJdk}";
    GRADLE_USER_HOME = "$HOME/.gradle";
  };
}
