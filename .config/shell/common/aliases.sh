# Common aliases for all shells
# This file is sourced by bash, zsh, and fish (via bass)

# Basic utilities
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias vim='nvim'
alias p='cd -'
alias s='cd ..'
alias cal='gcal'

# Listing (with .DS_Store hidden on macOS)
alias ls='ls --color=auto -I .DS_Store'
alias ll='ls -lG -I .DS_Store'
alias la='ls -alG -I .DS_Store'
alias l.='ls -dG .*'

# kubectl
alias k='kubectl'
alias y='yt-dlp'
alias ytb='youtube-dl -f bestvideo+bestaudio --merge-output-format mp4'

# Network
alias getip='wget http://ipinfo.io/ip -qO -'
alias weather='curl wttr.in/Koto'

# Proxy
alias surgeoff='unset http_proxy; unset https_proxy; unset all_proxy'
alias surgeon='export https_proxy=http://127.0.0.1:6152; export http_proxy=http://127.0.0.1:6152; export all_proxy=socks5://127.0.0.1:6153'

# Terraform
alias ipa='terraform init && terraform plan -out=plan.tfplan && terraform apply plan.tfplan'

# GitHub
alias github='gh repo view -w'

# Directories
alias cdi='cd ~/Library/Mobile\ Documents/com~apple~CloudDocs'

# Tools
alias aria='aria2c --conf-path="/Users/Archean/Misc/conf/aria2.conf" -D'
alias console='screen /dev/tty.usbserial-AD0JJ0DU'

# SSH connections are in ~/.aliases-sensitive
