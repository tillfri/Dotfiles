# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# yazi shell wrapper which changes directory on exit
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && [[ "$cwd" != *://* ]] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# copy last command and its output to clipboard
function copy_last_cmd_output() {
  { echo "❯ $(fc -ln -1)"; kitten @ get-text --extent last_non_empty_output --self; } \
  | kitty +kitten clipboard
}

zle -N copy_last_cmd_output

bindkey '^k' history-search-backward
bindkey '^j' history-search-forward
bindkey '^h' backward-word
bindkey '^l' forward-word
bindkey '^w' backward-kill-word
bindkey '^@' autosuggest-accept
bindkey '^f' copy_last_cmd_output

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='eza --long --color=always --icons=always --no-user --sort=modified'
alias c='clear'
alias edithypr='nvim ~/.config/hypr/hyprland.conf'
alias ssh='kitty +kitten ssh'
alias reload='hyprctl reload && source ~/.zshrc'
alias lg='lazygit'
alias n='nvim'
alias cat='bat'
alias man='batman'
alias du='du -h -d 1'
alias df='df -h'


# Env variables
export EDITOR=nvim
export PATH="$HOME/scripts:$HOME/.local/bin:$PATH"
export _ZO_EXCLUDE_DIRS="/mnt/stuff/*"

# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

# unbind alt+c
bindkey -M emacs '\ec' undefined-key

# Open the current command in your $EDITOR (e.g., neovim)
# Press Ctrl+X followed by Ctrl+E to trigger
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line


chpwd() {
  # If a venv is active, check whether we've left its tree
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_root="${VIRTUAL_ENV:h}"

    if [[ "$PWD" != "$venv_root" && "$PWD" != "$venv_root"/* ]]; then
      deactivate 2>/dev/null
    fi
  fi

  # Activate venv in current directory if none is active
  if [[ -z "$VIRTUAL_ENV" && -d .venv ]]; then
    source .venv/bin/activate
  fi
}


export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

. "$HOME/.local/bin/env"
