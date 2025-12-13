export PATH=~/.local/bin:/opt/homebrew/bin:$PATH

export LANG=en_US.UTF-8
export EDITOR="nvim"
alias vim="nvim"
alias vi="nvim"

alias ll="ls -l"
alias la="ls -la"

# never beep
setopt NO_BEEP

# terragrunt
alias tf=terraform
alias tg=terragrunt
export TG_PROVIDER_CACHE=true
export TG_DEPENDENCY_FETCH_OUTPUT_FROM_STATE=true
export TG_QUEUE_EXCLUDE_EXTERNAL=true
export TG_TF_PATH=$(which tofu)

##################################################################
# history
setopt SHARE_HISTORY
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt HIST_EXPIRE_DUPS_FIRST

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

# Git completion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

# Docker completion
fpath=(~/.docker/completions $fpath)

fpath+=~/.zfunc; 

eval "$(starship init zsh)"

##################################################################
# auto-completion
autoload -U compinit && compinit

