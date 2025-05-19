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
    rust
    go
    nodejs
    python3
    python311
    python312
    terraform
    awscli2
    aws-sam-cli
    firebase-cli
    gh
    wrangler
    ollama

    # Cloud & Kubernetes
    kubernetes-cli
    kubectl-ai
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
    lima
    orbstack

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
    wireshark
    termshark
    sniffnet
    vnstat
    iftop
    ngrok
    mitmproxy
    shadowsocks-libev
    openvpn
    openconnect
    tailscale
    cloudflare-warp

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

    # Media & Graphics
    ffmpeg
    imagemagick
    mpv
    yt-dlp
    graphviz
    poppler
    vips

    # Security & Encryption
    gnupg
    gpgme
    detect-secrets
    trufflehog
    sslyze
    dive
    crane
    skopeo

    # Testing & Performance
    hey
    vegeta
    wrk
    k6
    grpcui
    grpcurl

    # Version Management
    mise
    nvm
    pdm

    # Build Tools
    gcc
    llvm
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
    localsend
    mackup
    mosh
    qemu
    sapling
  ];
}