# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"

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

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

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
plugins=(git ripgrep)

source $ZSH/oh-my-zsh.sh

# User configuration
[ -e ~/.zsh_profile ] && source ~/.zsh_profile

SPACESHIP_PROMPT_ORDER=(
  time          # Time stamps section
  user          # Username section
  dir           # Current directory section
  host          # Hostname section
  git           # Git section (git_branch + git_status)
  hg            # Mercurial section (hg_branch  + hg_status)
  package       # Package version
  node          # Node.js section
  ruby          # Ruby section
  elixir        # Elixir section
  xcode         # Xcode section
  swift         # Swift section
  golang        # Go section
  php           # PHP section
  rust          # Rust section
  haskell       # Haskell Stack section
  julia         # Julia section
  docker        # Docker section
  #aws           # Amazon Web Services section
  #gcloud        # Google Cloud Platform section
  venv          # virtualenv section
  conda         # conda virtualenv section
  pyenv         # Pyenv section
  dotnet        # .NET section
  ember         # Ember.js section
  kubectl       # Kubectl context section
  terraform     # Terraform workspace section
  exec_time     # Execution time
  line_sep      # Line break
  #battery       # Battery level and status
  vi_mode       # Vi-mode indicator
  jobs          # Background jobs indicator
  exit_code     # Exit code section
  char          # Prompt character
)

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8
export LC_ALL=$LANG

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

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
alias "nvim."="nvim ."
alias gs="git s"
alias gds="gd --staged"
alias gba="git branch -a | fzf --ansi | cut -d ':' -f 2 | xargs echo | xargs git checkout"

# initialize nvm, if installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# ensure nvm path(s) are included in NODE_PATH
if [[ "$NODE_PATH" == "" ]]; then
  export NODE_PATH=$NODE_PATH:$(npm root -g)
fi

# nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# initialize pyenv, if installed
if [[ "$(command -v pyenv)" ]]; then
  eval "$(pyenv init -)"
fi

# global grep options
export GREP_OPTIONS='-iI --color --exclude-dir=.git'

# configure fuzzy finder to use ripgrep
export FZF_DEFAULT_COMMAND='rg --files --follow --hidden --no-ignore-vcs'

# path to NeoVim log file
export NVIM_LOG_FILE=~/.cache/nvim/log

# show current Kubernetes context on right-hand side of shell, if kubectl is installed
#if [[ -x "$(command -v kubectl)" ]]; then
  ## get current Kubernetes context
  #function print_kube_context() {
    #echo ${$(kubectl config current-context 2> /dev/null):-"(unknown)"}
  #}

  #RPROMPT='%{%B%F{blue}%}☸️  $(print_kube_context)%{%f%k%b%K{black}%B%F{green}%}'
#fi

# add paths to Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# add zsh command completion for Google Cloud CLI
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

function cloud_build_status() {
  local SHA=$1
  if [ -z $SHA ]; then
    SHA=$(git rev-parse HEAD)
  fi

  local GCP_PROJECT_ID=$(gcloud config list --format="value(core.project)")

  echo -e "Getting Cloud Build status for $(printf '\e[1m')$SHA$(printf '\e[0m') in $(printf '\e[1m')$GCP_PROJECT_ID$(printf '\e[0m')…"

  gcloud builds list --project $GCP_PROJECT_ID --filter="substitutions.COMMIT_SHA=$SHA" --format="table[box, title='$(printf '\e[1m')Build Status $GCP_PROJECT_ID$(printf '\e[0m')'](substitutions.SHORT_SHA, status, logUrl)"
}
alias cbs="cloud_build_status"

function mcd() {
  if [ -z "$1" ]; then
    echo "Usage: mcd <directory>" && return 1
  fi

  if [ ! -d $1 ]; then
    mkdir -p $1
  fi

  cd $1
}

# enable iTerm shell integration, if such a config exists for zsh
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# initialize zoxide
eval "$(zoxide init zsh)"
