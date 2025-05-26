# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="spaceship" # Disabling this in favor or Starship prompt

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=()

source $ZSH/oh-my-zsh.sh

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(starship init zsh)"

# User configuration
[ -e ~/.zsh_profile ] && source ~/.zsh_profile

# Ensure not just accidentally exiting a shell using e.g. `C-d`
# This is mainly to ensure tmux doesn't end the session when the shell in the last window exits
set -o ignoreeof # zsh
export IGNOREEOF=10 # bash

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=$LANG

setopt interactivecomments

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export VISUAL="nvim"
  export EDITOR="nvim"
else
  export VISUAL="nvim"
  export EDITOR="nvim"
fi

# aliases
alias ctags="$(brew --prefix)/bin/ctags"  # prefer Homebrew version of ctags
alias n="nvim"
alias "n."="nvim ."
alias "nvim."="nvim ."
alias g="git"
alias gb="git branch"
alias gd="git diff"
alias gs="git s"
alias gds="gd --staged"
alias gba="git branch -a | fzf --ansi | cut -d ':' -f 2 | xargs echo | sed -E 's/^(remotes\/[^\/]+\/)//' | xargs git checkout"
alias toggle_macos_dark_mode="osascript -e 'tell app \"System Events\" to tell appearance preferences to set dark mode to not dark mode'"
alias edit_day_note="view_day_note"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# initialize pyenv, if installed
if [[ "$(command -v pyenv)" ]]; then
  eval "$(pyenv init -)"
fi

# global grep options
export GREP_OPTIONS='-iI --color --exclude-dir=.git'

# fuzzy finder options
# - use ripgrep for file search (using its `--files` flag), tell it to:
#   - `--follow`: follow symbolic links
#   - `--hidden: `include "hidden" files
#   - `--no-ignore-vcs`: ignore VCS ignore files
export FZF_DEFAULT_COMMAND='rg --files --follow --hidden --no-ignore-vcs'
# - `--color=bw`: don't use colors since they don't respect the terminal's colorscheme
export FZF_DEFAULT_OPTS='--color=bw'

export RIPGREP_CONFIG_PATH="${HOME}/.ripgreprc"

# path to NeoVim log file
export NVIM_LOG_FILE=~/.cache/nvim/log

function mcd() {
  if [ -z "$1" ]; then
    echo "Usage: mcd <directory>" && return 1
  fi

  if [ ! -d $1 ]; then
    mkdir -p $1
  fi

  cd $1
}

function make_day_note() {
  formatted_date=$(date +"%Y-%m-%d")
  filename="${formatted_date}.md"
  nvim "${filename}"
}

function view_day_note() {
  formatted_date=$(date +"%Y-%m-%d")
  filename="${formatted_date}.md"
  if [[ ! -f ${filename} ]]; then
    echo "Couldn't find a day note for the current date (${formatted_date})"
    return 1
  fi
  nvim "${filename}"
}

function check_port_used() {
  port="$1"
  if [[ -z "${port}" ]]; then
    echo "Usage: check_port_used <port>" && return 1
  fi
  lsof -nP -iTCP -sTCP:LISTEN | grep "${port}"
}

function inspect_commit() {
  sha="$1"

  if [[ -z "${sha}" ]]; then
    echo "Usage: inspect_commit <commit-sha>"
    return 1
  fi

  git log -n 1 "${sha}"
  file=$(git show --name-only --pretty=format: "${sha}" | fzf --tmux=right --preview="git show --pretty=format: $sha -- {}" --preview-window=top)
  git show --pretty=format: "${sha}" -- "${file}"
}

# initialize zoxide
eval "$(zoxide init zsh)"

# keybindings/shortcuts
bindkey -s ^f "~/dev/dotfiles/tmux-pick-session\n"

# add paths to Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# add zsh command completion for Google Cloud CLI
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

# asdf
export ASDF_DATA_DIR="$HOME/.asdf"
export PATH="$ASDF_DATA_DIR/shims:$PATH"
