#!/bin/bash
# Populate the GLOBAL git identity in ~/.gitconfig.local (included by ~/.gitconfig).
# Always runs, but only prompts when a value is missing — idempotent and self-healing
# (re-prompts if ~/.gitconfig.local is ever deleted). TTY-guarded so a non-interactive
# apply won't hang on read. Values live only in ~/.gitconfig.local; nothing in chezmoi.
LOCAL_CONFIG="$HOME/.gitconfig.local"

if [ -z "$(git config --file "$LOCAL_CONFIG" user.name 2>/dev/null)" ]; then
  if [ -t 0 ]; then
    read -r -p "Full name for Git: " git_name
    [ -n "$git_name" ] && git config --file "$LOCAL_CONFIG" user.name "$git_name"
  else
    echo "No TTY; skipping Git user.name prompt. Set it later in $LOCAL_CONFIG."
  fi
fi

if [ -z "$(git config --file "$LOCAL_CONFIG" user.email 2>/dev/null)" ]; then
  if [ -t 0 ]; then
    read -r -p "Email for Git: " git_email
    [ -n "$git_email" ] && git config --file "$LOCAL_CONFIG" user.email "$git_email"
  else
    echo "No TTY; skipping Git user.email prompt. Set it later in $LOCAL_CONFIG."
  fi
fi
