# Common aliases for all shells
# This file is sourced by bash, zsh, and fish (via wrapper)

# Basic utilities
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias vim='nvim'
alias p='cd -'
alias s='cd ..'

# Listing
alias ls='ls --color=auto'
alias ll='ls -lG'
alias la='ls -alG'
alias l.='ls -dG .*'

# kubectl
alias k='kubectl'
alias y='yt-dlp'

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
