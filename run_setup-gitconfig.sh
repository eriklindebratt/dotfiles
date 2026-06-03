#!/bin/bash
# Populate the GLOBAL git identity in ~/.gitconfig.local (included by ~/.gitconfig).
# Always runs, but only prompts when a value is missing — idempotent and self-healing
# (re-prompts if ~/.gitconfig.local is ever deleted). Values live only in
# ~/.gitconfig.local; nothing is stored in chezmoi.
LOCAL_CONFIG="$HOME/.gitconfig.local"

# chezmoi does not attach the terminal to a script's stdin, so prompt via the
# controlling terminal (/dev/tty). If there is none (CI, piped), skip prompting.
if { : </dev/tty; } 2>/dev/null; then
  has_tty=1
else
  has_tty=0
fi

if [ -z "$(git config --file "$LOCAL_CONFIG" user.name 2>/dev/null)" ]; then
  if [ "$has_tty" = 1 ]; then
    read -r -p "Full name for Git: " git_name </dev/tty
    [ -n "$git_name" ] && git config --file "$LOCAL_CONFIG" user.name "$git_name"
  else
    echo "No terminal; set Git user.name later in $LOCAL_CONFIG."
  fi
fi

if [ -z "$(git config --file "$LOCAL_CONFIG" user.email 2>/dev/null)" ]; then
  if [ "$has_tty" = 1 ]; then
    read -r -p "Email for Git: " git_email </dev/tty
    [ -n "$git_email" ] && git config --file "$LOCAL_CONFIG" user.email "$git_email"
  else
    echo "No terminal; set Git user.email later in $LOCAL_CONFIG."
  fi
fi
