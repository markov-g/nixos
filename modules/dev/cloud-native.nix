{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ---- kubernetes core ----
    kubectl
    kubernetes-helm
    kustomize
    k9s
    kubectx # kubectx + kubens
    stern
    kubecolor
    krew

    # ---- local clusters ----
    kind # needs podman/docker; see containers.nix for the provider env
    minikube
    k3d
    kubectl-tree
    kubectl-node-shell

    # ---- gitops / delivery ----
    argocd
    fluxcd
    skaffold
    tilt
    helmfile

    # ---- policy / security / inspection ----
    kubeseal
    kube-score
    kubeconform
    popeye
    trivy
    cosign
    syft
    grype

    # ---- IaC & clouds (parity with awscli on your Mac) ----
    opentofu
    terragrunt
    ansible
    awscli2
    azure-cli
    google-cloud-sdk

    # ---- service mesh / networking ----
    cilium-cli
    istioctl

    # ---- registry / image plumbing ----
    skopeo
    crane
    dive
    regclient
  ];

  environment.variables = {
    KUBE_EDITOR = "nvim";
    # kind/testcontainers need to be told to use podman explicitly
    KIND_EXPERIMENTAL_PROVIDER = "podman";
    TESTCONTAINERS_RYUK_DISABLED = "true";
  };
}
