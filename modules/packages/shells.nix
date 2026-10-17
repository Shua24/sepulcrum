# Shells, terminals, and the CLI toolbox.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- shells and terminal
    yash
    ksh
    bash
    fish
    zsh
    starship
    tmux
    alacritty
    kitty
    wezterm
    ghostty
    foot
    xterm
    tty-clock
    cmatrix
    viu
    btop
    fastfetch
    duf
    lf
    tecla
    less
    man-db
    man-pages
    texinfo
    plocate
    nano
    micro
    neovim
    vim
    vis
    ripgrep
    fd
    fzf
    bat
    tree
    jq
    yq-go
    tig
    lazygit
    delta
    git
    git-lfs
    gh
    stow
    rsync
    pv
    wget
    curl
    unzip
    unrar
    zip
    p7zip
    file
    which
    psmisc
    procps
    htop
    glances
    ncdu
    dust
    dnsutils
    inetutils
    net-tools
    traceroute
    mtr
    whois
    socat
    nmap
    tcpdump
    bind
  
]
