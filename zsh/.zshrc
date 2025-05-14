# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall
eval "$(starship init zsh)"

# Show neofetch at startup
neofetch

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
source ~/completion-for-pnpm.bash

# Turso
export PATH="$HOME/.turso:$PATH"

# Pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
   case ":$PATH:" in
     *":$PNPM_HOME:"*) ;;
     *) export PATH="$PNPM_HOME:$PATH" ;;
   esac

# Lazy docker
export PATH="$HOME/.local/bin:$PATH"


# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
