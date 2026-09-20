{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # compilers - both, so you can reproduce CI on either
    gcc
    clang
    lld
    mold # much faster linker; use with -fuse-ld=mold

    # build systems
    gnumake
    cmake
    cmake-language-server
    ninja
    meson
    autoconf
    automake
    libtool
    pkg-config
    bear # generate compile_commands.json for non-cmake builds
    ccache

    # package managers
    conan
    # vcpkg needs a writable root; see notes in README
    vcpkg
    vcpkg-tool

    # language servers / tooling
    clang-tools # clangd, clang-format, clang-tidy
    cppcheck
    include-what-you-use

    # debug / profile
    gdb
    lldb
    valgrind
    perf
    heaptrack

    # docs / misc
    doxygen
    graphviz
  ];

  # ccache needs a shared cache dir if you want it across users.
  programs.ccache.enable = true;

  environment.variables = {
    CMAKE_GENERATOR = "Ninja";
  };
}
