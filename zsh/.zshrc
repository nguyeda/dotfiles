##################################################################
# environment
export PATH=~/.local/bin:$PATH
export LANG=en_US.UTF-8
export EDITOR="nvim"

# never beep
setopt NO_BEEP

##################################################################
# homebrew
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"

##################################################################
# aliases
alias vim="nvim"
alias vi="nvim"
alias ll="ls -l"
alias la="ls -la"

##################################################################
# tmux
alias t='tmux attach || tmux new'
if [[ -n "$TMUX" ]]; then
  alias tmux='echo "Already in tmux session"'
fi

##################################################################
# terragrunt
if command -v tofu &> /dev/null; then
  alias tf=tofu
  alias tg=terragrunt
  export TG_PROVIDER_CACHE=true
  export TG_DEPENDENCY_FETCH_OUTPUT_FROM_STATE=true
  export TG_QUEUE_EXCLUDE_EXTERNAL=true
  export TG_TF_PATH=$(which tofu)
fi

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

##################################################################
# auto-completion
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath+=~/.zsh                # git
fpath+=~/.docker/completions # docker
fpath+=~/.zfunc              # rustup, uv

autoload -U compinit && compinit

##################################################################
# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

##################################################################
# opencode
export PATH=/home/david/.opencode/bin:$PATH

##################################################################
# starship (keep last - initializes prompt)
eval "$(starship init zsh)"
