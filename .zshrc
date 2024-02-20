# Fix undercurl support in WezTerm
# https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
export TERM=wezterm

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/bin:/usr/sbin:/sbin:/usr/local/bin:/usr/local/sbin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
#ZSH_THEME="spaceship" # Disabling this in favor or Starship prompt. Remove this later?

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
plugins=(git ripgrep)

source $ZSH/oh-my-zsh.sh

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

eval "$(starship init zsh)"

# User configuration
[ -e ~/.zsh_profile ] && source ~/.zsh_profile

# Ensure not just accidentally exiting a shell using e.g. `C-d`
# This is mainly to ensure tmux doesn't end the session when the shell in the last window exits
set -o ignoreeof # zsh
export IGNOREEOF=10 # bash

# SPACESHIP_PROMPT_ORDER=(
#   time          # Time stamps section
#   user          # Username section
#   dir           # Current directory section
#   host          # Hostname section
#   git           # Git section (git_branch + git_status)
#   hg            # Mercurial section (hg_branch  + hg_status)
#   # package       # Package version
#   # node          # Node.js section
#   # ruby          # Ruby section
#   # elixir        # Elixir section
#   # xcode         # Xcode section
#   # swift         # Swift section
#   # golang        # Go section
#   # php           # PHP section
#   # rust          # Rust section
#   # haskell       # Haskell Stack section
#   # julia         # Julia section
#   # docker        # Docker section
#   # aws           # Amazon Web Services section
#   # gcloud        # Google Cloud Platform section
#   # venv          # virtualenv section
#   # conda         # conda virtualenv section
#   # dotnet        # .NET section
#   # kubectl       # Kubectl context section
#   # terraform     # Terraform workspace section
#   exec_time     # Execution time
#   line_sep      # Line break
#   #battery       # Battery level and status
#   jobs          # Background jobs indicator
#   exit_code     # Exit code section
#   char          # Prompt character
# )

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
alias "nvim."="nvim ."
alias gs="git s"
alias gds="gd --staged"
alias gba="git branch -a | fzf --ansi | cut -d ':' -f 2 | xargs echo | xargs git checkout"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

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

# configure fuzzy finder to use ripgrep
export FZF_DEFAULT_COMMAND='rg --files --follow --hidden --no-ignore-vcs'

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

# initialize zoxide
eval "$(zoxide init zsh)"

bindkey -s ^f "~/dev/dotfiles/tmux-pick-session\n"

# enable iTerm shell integration, if such a config exists for zsh
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# add paths to Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# add zsh command completion for Google Cloud CLI
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
