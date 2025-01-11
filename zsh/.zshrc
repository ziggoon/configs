export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="ziggoon"

plugins=(git)

source $ZSH/oh-my-zsh.sh
alias ohmyzsh="mate ~/.oh-my-zsh"

alias ls="exa"
alias pip="uv pip"
alias zbt="zig build test"
alias zbr="zig build run"
alias crr="cargo run --release"

bindkey '^e' beginning-of-line
bindkey '^r' end-of-line
