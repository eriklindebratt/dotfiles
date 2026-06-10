#!/usr/bin/env bash
# Claude Code status line
# Receives JSON on stdin
#
# ~/cwd · [wt] branch                    [model] · ████░░ 43% left · 12.3k tokens

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# Default: show cwd (fallback when not in a git repo)
display_dir="${cwd/#$HOME/~}"

# Inside a git repo: show the repo root, or the main (non-worktree) root when
# the worktree lives inside the main repo tree.
git_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
if [ -n "$git_root" ]; then
  common_dir=$(git -C "$cwd" --no-optional-locks rev-parse --git-common-dir 2>/dev/null)
  if [[ "$common_dir" == /* ]]; then
    main_root=$(dirname "$common_dir")
    if [[ "$git_root" == "$main_root"/* ]]; then
      display_dir="${main_root/#$HOME/~}"
    else
      display_dir="${git_root/#$HOME/~}"
    fi
  else
    display_dir="${git_root/#$HOME/~}"
  fi
fi

branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

is_worktree=false
worktree_session=$(echo "$input" | jq -r '.worktree.name // empty')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
[ -n "$worktree_session" ] || [ -n "$git_worktree" ] && is_worktree=true

model=$(echo "$input" | jq -r '.model.display_name // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')

cols=$(python3 -c "import os; print(os.get_terminal_size(2).columns)" 2>/dev/null)
[ -z "$cols" ] && cols=$(stty size <&2 2>/dev/null | awk '{print $2}')
[ -z "$cols" ] && cols=$(stty -f /dev/tty size 2>/dev/null | awk '{print $2}')
cols=${cols:-${COLUMNS:-120}}
cols=$(( cols - 3 ))  # account for Claude Code's internal right padding

# ── helpers ───────────────────────────────────────────────────────────────────

ESC=$'\033'
dim() { printf '\033[2m%s\033[0m' "$1"; }
sep() { dim ' · '; }

vlen() { printf '%s' "$1" | sed "s/${ESC}\[[0-9;]*m//g" | python3 -c "import sys; print(len(sys.stdin.read()))"; }

# Color based on context remaining: dim when fine, escalates as it runs out
ctx_color() {
  local pct=$1
  if   [ "$pct" -le 10 ] 2>/dev/null; then printf '\033[1;31m'  # bold red
  elif [ "$pct" -le 25 ] 2>/dev/null; then printf '\033[31m'    # red
  elif [ "$pct" -le 50 ] 2>/dev/null; then printf '\033[33m'    # yellow
  else                                      printf '\033[2m'     # dim
  fi
}

# Color based on token count: dim below 50k, escalates toward 100k+
tok_color() {
  local tokens=$1
  if   [ "$tokens" -ge 100000 ] 2>/dev/null; then printf '\033[1;31m'
  elif [ "$tokens" -ge 75000  ] 2>/dev/null; then printf '\033[31m'
  elif [ "$tokens" -ge 50000  ] 2>/dev/null; then printf '\033[33m'
  else                                             printf '\033[2m'
  fi
}

# Bar fills left-to-right with used context; dim green when fine, escalates
render_ctx_bar() {
  local pct=$1 width=10 filled empty bar_color pct_int filled_str='' empty_str=''
  filled=$(awk "BEGIN { printf \"%d\", (1 - $pct/100) * $width + 0.5 }")
  empty=$(( width - filled ))
  pct_int=$(printf '%.0f' "$pct")
  if   [ "$pct_int" -le 10 ]; then bar_color='\033[1;31m'  # bold red
  elif [ "$pct_int" -le 25 ]; then bar_color='\033[31m'    # red
  elif [ "$pct_int" -le 50 ]; then bar_color='\033[33m'    # yellow
  else                              bar_color='\033[2m'    # dim — context is fine
  fi
  for (( i=0; i<filled; i++ )); do filled_str="${filled_str}█"; done
  for (( i=0; i<empty;  i++ )); do empty_str="${empty_str}░"; done
  printf "${bar_color}%s\033[0m\033[2m%s\033[0m" "$filled_str" "$empty_str"
}

# ── left: dir + branch ────────────────────────────────────────────────────────

left="$(printf '\033[1m%s\033[0m' "$display_dir")"

if [ -n "$branch" ]; then
  branch_str="$(printf '\033[36m%s\033[0m' "$branch")"
  if $is_worktree; then
    wt_tag="$(printf '\033[38;5;214m%s\033[0m' '󰙅')"
    left="${left}$(sep)${wt_tag} ${branch_str}"
  else
    left="${left}$(sep)${branch_str}"
  fi
fi

# ── right: model · ctx bar · tokens ──────────────────────────────────────────

right_parts=()

[ -n "$model" ] && right_parts+=("$(dim "$model")")

if [ -n "$remaining" ]; then
  bar=$(render_ctx_bar "$remaining")
  pct=$(printf '%.0f' "$remaining")
  color=$(ctx_color "$pct")
  right_parts+=("${bar} $(printf "${color}%s%%\033[0m" "$pct") $(printf "${color}%s\033[0m" "left")")
fi

if [ -n "$total_tokens" ]; then
  if   [ "$total_tokens" -ge 1000000 ] 2>/dev/null; then
    fmt=$(awk "BEGIN { printf \"%.1fM\", $total_tokens / 1000000 }")
  elif [ "$total_tokens" -ge 1000    ] 2>/dev/null; then
    fmt=$(awk "BEGIN { printf \"%.1fk\", $total_tokens / 1000 }")
  else
    fmt="$total_tokens"
  fi
  color=$(tok_color "$total_tokens")
  right_parts+=("$(printf "${color}%s\033[0m" "${fmt} tokens")")
fi

right=''
for p in "${right_parts[@]}"; do
  [ -z "$right" ] && right="$p" || right="${right}$(sep)${p}"
done

# ── compose ───────────────────────────────────────────────────────────────────

left_len=$(vlen "$left")
right_len=$(vlen "$right")
gap=$(( cols - left_len - right_len ))
[ "$gap" -lt 1 ] && gap=1
printf '%s%*s%s' "$left" "$gap" '' "$right"
