export PATH=/opt/homebrew/bin:$PATH

export LANG=en_US.UTF-8
export EDITOR="nvim"
alias vim="nvim"
alias vi="nvim"

alias ll="ls -l"
alias la="ls -la"

# never beep
setopt NO_BEEP

# History
setopt SHARE_HISTORY
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt HIST_EXPIRE_DUPS_FIRST

# terragrunt
alias tf=terraform
alias tg=terragrunt
export TG_PROVIDER_CACHE=true
export TG_DEPENDENCY_FETCH_OUTPUT_FROM_STATE=true
export TG_QUEUE_EXCLUDE_EXTERNAL=true
export TG_TF_PATH=$(which terraform)
	
# Python
alias python=/opt/homebrew/bin/python3

##################################################################
# auto-completion

# history
autoload -U compinit && compinit
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# Git completion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)

eval "$(starship init zsh)"
