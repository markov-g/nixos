{ pkgs, ... }:

let
  # A system interpreter with the batteries you actually want globally.
  # Per-project work should go through uv or a flake devShell, not this.
  pythonEnv = pkgs.python313.withPackages (ps: with ps; [
    pip
    virtualenv
    ipython
    requests
    rich
  ]);
in
{
  environment.systemPackages = with pkgs; [
    pythonEnv

    # project / env managers
    uv # primary: fast, handles interpreters and locking
    poetry
    # tests fail upstream on 26.05 (PEP 508 whitespace assertions); cosmetic
    (python313Packages.pipx.overridePythonAttrs (_: { doCheck = false; }))
    pdm
    hatch

    # lint / format / types
    ruff
    black
    isort
    mypy
    pyright
    basedpyright

    # test / debug
    python313Packages.pytest
    python313Packages.pytest-cov
    python313Packages.debugpy

    # notebooks
    jupyter

    # native build deps that wheels commonly want
    stdenv.cc
    zlib
    openssl
    libffi
  ];

  environment.variables = {
    # Let uv manage interpreters instead of silently using the Nix one.
    UV_PYTHON_PREFERENCE = "managed";
    PYTHONDONTWRITEBYTECODE = "1";
  };
}
