# common/base-packages.nix
{ pkgs }:
{
  packages = with pkgs; [
    # Shell and Terminal
    fish
    zsh
    bash
    starship
    tmux
    neovim
    lazygit
    thefuck
    tig
    onefetch
    neofetch

    # Development Tools
    git
    stow
    pre-commit
    rustup
    go
    nodejs_20
    python3
    terraform
    awscli2
    aws-sam-cli
    firebase-tools
    gh
    wrangler # Cloudflare Wrangler CLI
    ollama   # Runs on Linux

    # Cloud & Kubernetes
    kubectl
    k9s
    kind
    minikube
    helm
    helmfile
    kustomize
    skaffold
    argocd
    istioctl
    cilium-cli
    eksctl
    docker
    docker-compose
    podman

    # Network Tools
    curl
    wget
    httpie
    mtr
    nmap
    socat
    ipcalc
    iperf3
    tcptraceroute
    termshark
    vnstat
    iftop
    ngrok
    mitmproxy
    openconnect
    tailscale

    # System & Monitoring
    htop
    btop
    gotop
    ncdu
    dust
    stress-ng
    watch

    # File & Text Processing
    bat
    fd
    ripgrep
    fzf
    zoxide
    tree
    jq
    yq
    glow
    urlview
    gnugrep
    gnused
    gnutar
    gzip
    coreutils
    findutils
    gawk

    # Media & Graphics (CLI tools are fine)
    ffmpeg
    imagemagick
    mpv
    yt-dlp
    graphviz
    vips

    # Security & Encryption
    gnupg
    detect-secrets
    trufflehog
    sslyze
    dive      # Docker image analyzer
    crane     # Tool for interacting with container registries
    skopeo    # Tool for container image operations

    # Testing & Performance
    hey
    vegeta
    wrk
    k6
    grpcui
    grpcurl

    # Version Management
    mise
    pdm

    # Build Tools
    gcc
    autoconf
    automake
    pkg-config
    bison
    yasm

    # Documentation
    hugo

    # Utilities
    gcal
    croc
    mosh
  ];
}