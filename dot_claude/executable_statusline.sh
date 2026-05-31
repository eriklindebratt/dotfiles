#!/usr/bin/env bash
# Claude Code status line — mirrors the default Starship prompt style
# Receives JSON on stdin

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
home="$HOME"
# Replace $HOME prefix with ~
display_dir="${cwd/#$home/~}"

# Git branch (skip optional lock to avoid blocking)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Model display name
model=$(echo "$input" | jq -r '.model.display_name // empty')

# Context remaining percentage
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Total input tokens used in the session
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')

# Build the status line
parts=()

# Directory (bold cyan)
parts+=("$(printf '\033[1;36m%s\033[0m' "$display_dir")")

# Git branch (bold magenta), if available
if [ -n "$branch" ]; then
  parts+=("$(printf '\033[1;35m%s\033[0m' " $branch")")
fi

# Model (dim)
if [ -n "$model" ]; then
  parts+=("$(printf '\033[2m%s\033[0m' "$model")")
fi

# Context usage (dim), only when available: "tokens used  ctx: remaining%"
if [ -n "$total_tokens" ] || [ -n "$remaining" ]; then
  ctx_str=""
  if [ -n "$total_tokens" ]; then
    # Format tokens: show as e.g. "12.3k" or "1.2M"
    if [ "$total_tokens" -ge 1000000 ] 2>/dev/null; then
      formatted=$(awk "BEGIN { printf \"%.1fM\", $total_tokens / 1000000 }")
    elif [ "$total_tokens" -ge 1000 ] 2>/dev/null; then
      formatted=$(awk "BEGIN { printf \"%.1fk\", $total_tokens / 1000 }")
    else
      formatted="$total_tokens"
    fi
    ctx_str="${formatted} tokens"
  fi
  if [ -n "$remaining" ]; then
    [ -n "$ctx_str" ] && ctx_str="$ctx_str  "
    ctx_str="${ctx_str}ctx: $(printf '%.0f' "$remaining")%"
  fi
  parts+=("$(printf '\033[2m%s\033[0m' "$ctx_str")")
fi

# Join parts with a separator
sep="$(printf '\033[2m  \033[0m')"
result=""
for part in "${parts[@]}"; do
  if [ -z "$result" ]; then
    result="$part"
  else
    result="$result$sep$part"
  fi
done

printf '%s' "$result"
