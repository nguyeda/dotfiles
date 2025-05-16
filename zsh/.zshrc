# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# Allow to type a directory name without prefixing it with "cd"
setopt autocd
# Set the shell to "emacs" mode. You can use -v instead to use the "ui" mode
bindkey -e
# End of lines configured by zsh-newuser-install

# Bind Ctrl+Right to move forward a word
bindkey '^[[1;5C' forward-word
# Bind Ctrl+Left to move backward a word
bindkey '^[[1;5D' backward-word

# The following lines were added by compinstall

zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*:default' menu select=0
zstyle :compinstall filename "$HOME/.zshrc"

autoload -Uz compinit
compinit
# End of lines added by compinstall

# Initialiaze starhsip
eval "$(starship init zsh)"

# Initialize zoxyde
eval "$(zoxide init zsh)"

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
