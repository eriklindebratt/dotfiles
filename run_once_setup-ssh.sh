#!/bin/bash
# Optional, per-machine personal SSH identity for the dotfiles repo.
# Everything is gathered via prompts and written ONLY to the dotfiles repo's own
# .git/config + .git/hooks and ~/.ssh/config — nothing is stored in chezmoi.
#
# Two paths:
#   - Already set up (hooks.sshKey set and the key exists): offer to set it up
#     again — make sure commits/pushes use your personal Git identity, route
#     origin through the ssh alias, and edit ~/.ssh/config. This runs only after
#     an interactive y/N; with no controlling terminal it does nothing and
#     leaves everything untouched — nothing here is modified without a
#     confirmation.
#   - Otherwise: full interactive setup below.
#
# Because this is run_once, declining now means it won't re-run automatically. To
# set it up later, run this script manually or clear its chezmoi script state.

# Dedicated ssh Host alias for this repo's origin. With the remote on the alias,
# only the alias' Host block matches (ssh matches on the name as typed, not the
# resolved HostName), so the personal key is the ONLY key ssh offers — even on
# machines whose `Host github.com` entry carries another identity. A plain
# git@github.com remote does not get that guarantee: both that block's
# IdentityFile and core.sshCommand's -i count as "explicit" identities, and ssh
# offers agent-resident explicit keys first — i.e. the other account's key can
# win whenever it is in the agent and the personal key is not.
alias_host="github-personal"

# Use chezmoi's injected env var — calling `chezmoi` directly here deadlocks
# because chezmoi is already the process running this script.
repo="${CHEZMOI_SOURCE_DIR:-$(chezmoi source-path 2>/dev/null)}"
if [ -z "$repo" ] || [ ! -d "$repo/.git" ]; then
  echo "Could not resolve the chezmoi source repo (.git not found at '$repo'); aborting." >&2
  exit 1
fi

ssh_dir="$HOME/.ssh"
ssh_config="$ssh_dir/config"

# Ensure ~/.ssh/config has a Host block for $alias_host pointing at the given key.
# Existence is checked with `ssh -G` rather than grep so a block defined via an
# Include also counts. If the alias exists but resolves to a different key or
# hostname, warn and leave it alone — we never rewrite pre-existing ssh config.
# Returns 0 when the alias resolves to github.com with the given key (or was just
# added), 1 when an existing block was left in place that the pre-push hook will
# block on until it is fixed by hand.
ensure_alias_block() {
  local key="$1" resolved_hostname resolved_keys key_display
  resolved_hostname="$(ssh -G "$alias_host" 2>/dev/null | awk '/^hostname /{print $2}')"
  if [ "$resolved_hostname" = "github.com" ]; then
    # Block already present. Warn (never rewrite) if it points at a different key.
    # `sed -n 's/^identityfile //p'` keeps the whole path — robust to spaces, unlike
    # awk '{print $2}'; ssh -G emits the path with ~ unexpanded, so fold it to $HOME.
    resolved_keys="$(ssh -G "$alias_host" 2>/dev/null | sed -n 's/^identityfile //p' | sed "s|^~|$HOME|")"
    if [ "$resolved_keys" != "$key" ]; then
      echo "WARNING: 'Host $alias_host' already exists in your ssh config but resolves to:" >&2
      printf '%s\n' "$resolved_keys" | sed 's/^/    /' >&2
      echo "  instead of the selected key: $key" >&2
      echo "  (If a 'Host *' block in your ssh config also sets IdentityFile, that key shows" >&2
      echo "  up here too — remove it from 'Host *' so only this alias' key is offered.)" >&2
      echo "  Left untouched — align its IdentityFile manually; pushes are blocked until then." >&2
      return 1
    fi
    return 0
  elif [ "$resolved_hostname" != "$alias_host" ]; then
    # A 'Host $alias_host' block exists but points somewhere other than github.com
    # (when no block matches, ssh -G echoes the literal alias back as the hostname).
    # Don't append a duplicate — warn and leave it for manual reconciliation.
    echo "WARNING: 'Host $alias_host' already exists but resolves to HostName '$resolved_hostname', not github.com." >&2
    echo "  Left untouched to avoid a duplicate block; edit your ssh config so that" >&2
    echo "  'Host $alias_host' has 'HostName github.com', or remove the block and re-run." >&2
    return 1
  fi

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
  if [ ! -f "$ssh_config" ]; then
    touch "$ssh_config"
    chmod 600 "$ssh_config"
  fi
  # Append, never prepend — e.g. OrbStack's Include must stay at the top of the file.
  key_display="${key/#$HOME/\~}"
  {
    echo ""
    echo "# Personal GitHub identity for the dotfiles repo — added by setup-ssh (chezmoi)"
    echo "Host $alias_host"
    echo "  HostName github.com"
    echo "  IdentityFile $key_display"
    echo "  IdentitiesOnly yes"
  } >>"$ssh_config"
  echo "Added 'Host $alias_host' to $ssh_config (IdentityFile $key_display)."
}

# Point origin at the alias so pushes can only ever offer the personal key.
# Rewrites github.com URLs only (HTTPS or SSH) — turning an arbitrary host's URL
# into the matching SSH one is host-specific and easy to get wrong, so other
# hosts just get a heads-up; the pre-push hook blocks pushes until origin uses
# the alias, so this is a nudge, not a hard failure. Returns 0 when origin is on
# the alias afterwards, 1 when the caller must still move it by hand.
ensure_remote() {
  local origin_url path new_url
  origin_url="$(git -C "$repo" config remote.origin.url)"
  case "$origin_url" in
    git@"$alias_host":* | ssh://git@"$alias_host"/*)
      return 0 ;; # already on the alias — nothing to do
    https://github.com/* | git@github.com:* | ssh://git@github.com/*)
      path="${origin_url#https://github.com/}"
      path="${path#git@github.com:}"
      path="${path#ssh://git@github.com/}"
      new_url="git@$alias_host:${path%.git}.git"
      git -C "$repo" remote set-url origin "$new_url"
      echo "Rewrote origin: $origin_url -> $new_url"
      return 0
      ;;
    *)
      echo "NOTE: origin is '$origin_url' (not a github.com URL); pushes are blocked" >&2
      echo "until it uses the '$alias_host' alias, e.g.:" >&2
      echo "  git -C \"$repo\" remote set-url origin git@$alias_host:<owner>/<repo>.git" >&2
      return 1
      ;;
  esac
}

# Guard hooks: block commits/pushes made under the wrong identity or via the
# wrong remote/key. They read the expected values from the repo's git config at
# run time rather than having them baked into their text, so a value containing
# quotes (or $, backticks) can't produce a malformed hook script. Heredocs are
# quoted (<<'EOF') so the hook bodies are written verbatim.
install_hooks() {
  local hook_dir="$repo/.git/hooks"

  cat >"$hook_dir/pre-commit" <<'EOF'
#!/bin/bash
expected_name="$(git config hooks.expectedName)"
expected_email="$(git config hooks.expectedEmail)"
actual_name="$(git config user.name)"
actual_email="$(git config user.email)"
if [ "$actual_name" != "$expected_name" ] || [ "$actual_email" != "$expected_email" ]; then
  echo "BLOCKED: dotfiles repo commit identity ($actual_name <$actual_email>) != expected ($expected_name <$expected_email>)" >&2
  echo "Fix: git config user.name \"$expected_name\" && git config user.email \"$expected_email\"" >&2
  exit 1
fi
EOF

  cat >"$hook_dir/pre-push" <<'EOF'
#!/bin/bash
expected_name="$(git config hooks.expectedName)"
expected_email="$(git config hooks.expectedEmail)"
actual_name="$(git config user.name)"
actual_email="$(git config user.email)"
if [ "$actual_name" != "$expected_name" ] || [ "$actual_email" != "$expected_email" ]; then
  echo "BLOCKED: dotfiles repo push identity ($actual_name <$actual_email>) != expected ($expected_name <$expected_email>)" >&2
  exit 1
fi
remote="$(git config remote.origin.url)"
# Enforce SSH so pushes use the key/identity above, not a cached HTTPS credential.
case "$remote" in
  git@* | ssh://*) ;;
  *) echo "BLOCKED: origin is not an SSH URL ($remote)" >&2; exit 1 ;;
esac
key="$(git config hooks.sshKey)"
key="${key/#\~/$HOME}"
if [ -n "$key" ] && [ ! -f "$key" ]; then
  echo "BLOCKED: SSH key recorded for this repo not found: $key" >&2
  exit 1
fi
# When an alias is recorded: require origin to use it, require the alias to
# resolve (a deleted ssh config block otherwise surfaces as a cryptic DNS
# error), and require it to resolve to exactly the recorded key — a second
# candidate key would reintroduce the wrong-account ambiguity this setup
# exists to prevent. `ssh -G` only parses local config; no network involved.
alias_host="$(git config hooks.sshHostAlias)"
if [ -n "$alias_host" ]; then
  case "$remote" in
    git@"$alias_host":* | ssh://git@"$alias_host"/*) ;;
    *)
      echo "BLOCKED: origin must use the '$alias_host' alias (got: $remote)" >&2
      echo "Fix: git remote set-url origin git@$alias_host:<owner>/<repo>.git" >&2
      exit 1
      ;;
  esac
  resolved_hostname="$(ssh -G "$alias_host" 2>/dev/null | awk '/^hostname /{print $2}')"
  if [ "$resolved_hostname" != "github.com" ]; then
    echo "BLOCKED: 'Host $alias_host' does not resolve to github.com in your ssh config" >&2
    echo "(missing block?). Re-run setup-ssh / chezmoi apply to restore it." >&2
    exit 1
  fi
  # sed (not awk '{print $2}') so a key path containing spaces survives intact.
  resolved_keys="$(ssh -G "$alias_host" 2>/dev/null | sed -n 's/^identityfile //p' | sed "s|^~|$HOME|")"
  if [ "$resolved_keys" != "$key" ]; then
    echo "BLOCKED: 'Host $alias_host' resolves to different key(s) than the recorded $key:" >&2
    printf '%s\n' "$resolved_keys" | sed 's/^/    /' >&2
    echo "(If a 'Host *' block in your ssh config also sets IdentityFile, that key shows" >&2
    echo "up here too — remove it from 'Host *' so only this alias' key is offered.)" >&2
    echo "Align the IdentityFile in your ssh config with hooks.sshKey." >&2
    exit 1
  fi
fi
EOF

  chmod +x "$hook_dir/pre-commit" "$hook_dir/pre-push"
}

# Is a controlling terminal available to prompt on? (chezmoi runs scripts with
# stdin detached, so we test /dev/tty directly rather than -t 0.)
has_tty() { { : </dev/tty; } 2>/dev/null; }

# --- Already set up? Offer to set it up again, then exit. ---------------------
# Setting it up again changes things — it makes sure commits/pushes use your
# personal Git identity, routes origin through the ssh alias, and edits
# ~/.ssh/config. None of it happens without an interactive confirmation: with no
# controlling terminal we leave everything untouched. (Not drift recovery
# either — the pre-push hook blocks pushes until you re-run this in a terminal
# and confirm.)
configured_key="$(git -C "$repo" config hooks.sshKey)"
configured_key="${configured_key/#\~/$HOME}"
if [ -n "$configured_key" ]; then
  if [ -f "$configured_key" ]; then
    if ! has_tty; then
      echo "This repo already has a personal SSH key recorded ($configured_key), and that"
      echo "key exists on disk — so personal SSH is already set up. This run has no terminal"
      echo "to confirm changes on, so nothing was modified. Run this script from an"
      echo "interactive terminal if you want to set it up again."
      exit 0
    fi
    echo "This repo already has a personal SSH key recorded ($configured_key), and that"
    echo "key exists on disk — so personal SSH is already set up."
    echo
    echo "If you want to, you can set it up again. This will:"
    echo "  1. make sure commits and pushes here go out under your personal Git identity,"
    echo "     not a work one"
    echo "  2. route this repo's remote through a dedicated '$alias_host' SSH alias so"
    echo "     only your personal key is offered to GitHub, rewriting origin to"
    echo "     git@$alias_host:<owner>/<repo>.git"
    echo "  3. add a 'Host $alias_host' block to $ssh_config"
    echo
    read -r -p "Set it up again now? (y/N) " response </dev/tty
    case "$response" in
      [yY][eE][sS] | [yY]) ;;
      *) echo "Left everything untouched."; exit 0 ;;
    esac
    git -C "$repo" config core.sshCommand "ssh -i \"$configured_key\" -o IdentitiesOnly=yes"
    git -C "$repo" config hooks.sshHostAlias "$alias_host"
    install_hooks
    ok=true
    ensure_alias_block "$configured_key" || ok=false
    ensure_remote || ok=false
    if $ok; then
      echo "Done — personal SSH set up for the dotfiles repo at $repo."
    else
      echo "Personal SSH set up for the dotfiles repo at $repo — but pushes stay blocked"
      echo "until the warning(s) above are fixed."
    fi
    exit 0
  fi
  echo "WARNING: recorded personal SSH key '$configured_key' no longer exists; running full setup." >&2
fi

# --- Full interactive setup. ---------------------------------------------------

# chezmoi does not attach the terminal to a script's stdin, so prompt via the
# controlling terminal (/dev/tty). If there is none (CI, piped), skip.
if ! has_tty; then
  echo "No terminal; skipping personal SSH setup. Re-run this script manually to set it up."
  exit 0
fi

read -r -p "Set up personal SSH key/identity for this machine? (y/N) " response </dev/tty
case "$response" in
  [yY][eE][sS]|[yY]) ;;
  *) echo "Skipping personal SSH setup."; exit 0 ;;
esac

read -r -p "Personal Git name: " personal_git_name </dev/tty
read -r -p "Personal Git email: " personal_git_email </dev/tty

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# Collect existing private keys (skip .pub and non-key files).
keys=()
for f in "$ssh_dir"/*; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in
    *.pub | known_hosts | known_hosts.old | config | authorized_keys) continue ;;
  esac
  keys+=("$f")
done

new_key="$ssh_dir/id_personal"
selected_key=""

if [ ${#keys[@]} -gt 0 ]; then
  echo "Existing private keys in $ssh_dir:"
  i=1
  for k in "${keys[@]}"; do
    echo "  $i) $k"
    i=$((i + 1))
  done
  echo "  $i) Generate a new ed25519 key at $new_key"
  # $i is the "generate new" option; valid choices are 1..$i. Re-prompt on bad input.
  while true; do
    if ! read -r -p "Choose [1-$i]: " choice </dev/tty; then
      echo "No input; aborting personal SSH setup." >&2
      exit 1
    fi
    if [ "$choice" = "$i" ]; then
      ssh-keygen -t ed25519 -f "$new_key" -C "$personal_git_email"
      selected_key="$new_key"
      break
    elif [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -lt "$i" ] 2>/dev/null; then
      selected_key="${keys[$((choice - 1))]}"
      break
    else
      echo "Invalid choice '$choice'; enter a number between 1 and $i." >&2
    fi
  done
else
  echo "No existing private keys found; generating an ed25519 key at $new_key"
  ssh-keygen -t ed25519 -f "$new_key" -C "$personal_git_email"
  selected_key="$new_key"
fi

echo
echo "Add this public key to GitHub (Settings -> SSH and GPG keys -> New SSH key):"
echo
cat "${selected_key}.pub"
echo
read -r -p "Press Enter once the key is added to GitHub... " _ </dev/tty

git -C "$repo" config user.name "$personal_git_name"
git -C "$repo" config user.email "$personal_git_email"
# Kept alongside the alias as a second layer: even if the remote is somehow
# changed to plain github.com, the personal key is at least in the offered set.
git -C "$repo" config core.sshCommand "ssh -i \"$selected_key\" -o IdentitiesOnly=yes"

# Store the expected identity in the repo's git config for the guard hooks.
git -C "$repo" config hooks.expectedName "$personal_git_name"
git -C "$repo" config hooks.expectedEmail "$personal_git_email"
# Record the chosen key's path for the pre-push hook to verify. Stored directly (always
# an absolute path) so the hook needn't parse core.sshCommand — robust even with spaces.
git -C "$repo" config hooks.sshKey "$selected_key"
git -C "$repo" config hooks.sshHostAlias "$alias_host"

install_hooks
ok=true
ensure_alias_block "$selected_key" || ok=false
ensure_remote || ok=false
if $ok; then
  echo "Personal SSH identity configured for the dotfiles repo at $repo."
else
  echo "Personal SSH identity configured for the dotfiles repo at $repo — but pushes"
  echo "stay blocked until the warning(s) above are fixed."
fi
