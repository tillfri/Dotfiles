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

### FUNCTIONS ###

# alias function to quickfire a question to a free model
function q() { opencode run -m github-copilot/gpt-5-mini "$*" }

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

# interactive jump picker
function zoxide_fzf() {
  local dir
  zle -I
  dir=$(zoxide query -i) || return
  cd "$dir"
  zle reset-prompt
}
zle -N zoxide_fzf

# open file(s) selected via fzf directly in nvim
my-fzf-file-widget() {
    local selected

    selected=$(
	fd --hidden -t f \
	    --exclude '.git' \
	    --exclude '.cache' \
	    --exclude '.npm' \
	    --exclude '.cargo' \
	    --exclude '.rustup' \
	    --exclude '.mozilla' \
	    --exclude '.thunderbird' \
	    --exclude '.wine' \
	    --exclude '.steam' \
	    --exclude '.var' \
	    --exclude '.gradle' \
	    --exclude '.gnupg' \
	    --exclude '.local' \
	    --exclude '.bun' \
	    --exclude '.pki' |
	fzf -m \
	    --layout=reverse \
	    --preview 'bat --style=numbers --color=always {} 2>/dev/null || xxd {} | head -50' \
	    --preview-window=down,60%
    )

    if [[ -n "$selected" ]]; then
	zle push-input
	BUFFER="nvim ${(j: :)${(q)${(f)selected}}}"
	zle accept-line
    else
	zle reset-prompt
    fi
}
zle -N my-fzf-file-widget

# start opencode with oh-my-opencode
function omo() {
  local config_file="$HOME/.config/opencode/opencode.json"
  local updated_json

  updated_json=$(jq '
    .plugin = (
      (.plugin // [])
      | if any(.[]; test("^oh-my-opencode(@.*)?$")) then
	  .
	else
	  . + ["oh-my-opencode@latest"]
	end
    )
  ' "$config_file")

  OPENCODE_CONFIG_CONTENT="$updated_json" opencode "$@"
}

# wrapper for tar + ssh to copy local directory as compressed stream to remote machine
function transfer_dir() {
  if [ "$#" -ne 3 ]; then
    echo "Usage: transfer_dir <source_dir> <remote_host> <remote_target_dir>"
    return 1
  fi

  local source_dir="$1"
  local remote_host="$2"
  local remote_target_dir="$3"

  source_dir="${source_dir%/}"

  local parent_dir
  parent_dir="$(dirname "$source_dir")"
  local base_dir
  base_dir="$(basename "$source_dir")"

  # Save and restore pipefail to avoid affecting the caller's shell options
  local pipefail_state
  [[ -o pipefail ]] && pipefail_state=1 || pipefail_state=0
  set -o pipefail

  if command -v pv &>/dev/null; then
    tar -C "$parent_dir" -czf - "$base_dir" | \
      pv -s "$(\du -sb "$source_dir" | cut -f1)" | \
      \ssh "$remote_host" "mkdir -p '$remote_target_dir' && cd '$remote_target_dir' && tar -xzf -"
  else
    echo "Warning: pv not found, running without progress indicator" >&2
    tar -C "$parent_dir" -czf - "$base_dir" | \
      \ssh "$remote_host" "mkdir -p '$remote_target_dir' && cd '$remote_target_dir' && tar -xzf -"
  fi

  local exit_code=$?

  # Restore original pipefail state
  [ "$pipefail_state" -eq 0 ] && set +o pipefail

  return $exit_code
}

# download youtube/soundcloud as .wav
function yda() {
  yt-dlp --continue -P "/mnt/stuff/Music" -o "%(title)s.%(ext)s" --no-playlist --no-check-certificate --format=bestaudio -x --audio-format wav "$1"
}

### BINDS ###
# bindkey '^k' history-search-backward
# bindkey '^j' history-search-forward
bindkey '^j' backward-word
bindkey '^k' forward-word
bindkey '^w' kill-word
bindkey '^@' autosuggest-accept
bindkey '^y' copy_last_cmd_output
bindkey '^r' history-incremental-search-backward
bindkey '^z' zoxide_fzf
bindkey '^f' my-fzf-file-widget
bindkey '^a' beginning-of-line
bindkey '^d' end-of-line

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
alias ports='ss -ltnpH \
| awk "{print \$4}" \
| sed "s/.*://" \
| sort -n \
| while read -r port; do \
    c=$(docker ps --format "{{.Names}} {{.Ports}}" \
      | grep -E "0\\.0\\.0\\.0:${port}->|\\[::\\]:${port}->" \
      | awk "{print \$1}"); \
    printf "%-6s %s\n" "$port" "${c:-host}"; \
  done'
alias oc='opencode'

# Compression
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }
alias decompress="tar -xzf"

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
