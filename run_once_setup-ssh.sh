#!/bin/bash
# Optional, per-machine personal SSH identity for the dotfiles repo. Runs once.
# Everything is gathered via prompts and written ONLY to the dotfiles repo's own
# .git/config and .git/hooks — nothing is stored in chezmoi.
#
# Because this is run_once, declining now means it won't re-run automatically. To
# set it up later, run this script manually or clear its chezmoi script state.

# chezmoi does not attach the terminal to a script's stdin, so prompt via the
# controlling terminal (/dev/tty). If there is none (CI, piped), skip.
if ! { : </dev/tty; } 2>/dev/null; then
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

ssh_dir="$HOME/.ssh"
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

# Use chezmoi's injected env var — calling `chezmoi` directly here deadlocks
# because chezmoi is already the process running this script.
repo="${CHEZMOI_SOURCE_DIR:-$(chezmoi source-path 2>/dev/null)}"
if [ -z "$repo" ] || [ ! -d "$repo/.git" ]; then
  echo "Could not resolve the chezmoi source repo (.git not found at '$repo'); aborting." >&2
  exit 1
fi

git -C "$repo" config user.name "$personal_git_name"
git -C "$repo" config user.email "$personal_git_email"
git -C "$repo" config core.sshCommand "ssh -i $selected_key"
git -C "$repo" remote set-url origin git@github.com:eriklindebratt/dotfiles.git

# Guard hooks: block commits/pushes made under the wrong identity. Both bake in the
# personal name/email chosen above; pre-push additionally verifies the SSH remote
# and that the key referenced by core.sshCommand still exists.
hook_dir="$repo/.git/hooks"

cat >"$hook_dir/pre-commit" <<EOF
#!/bin/bash
expected_name="$personal_git_name"
expected_email="$personal_git_email"
actual_name="\$(git config user.name)"
actual_email="\$(git config user.email)"
if [ "\$actual_name" != "\$expected_name" ] || [ "\$actual_email" != "\$expected_email" ]; then
  echo "BLOCKED: dotfiles repo commit identity (\$actual_name <\$actual_email>) != expected (\$expected_name <\$expected_email>)" >&2
  echo "Fix: git config user.name \"\$expected_name\" && git config user.email \"\$expected_email\"" >&2
  exit 1
fi
EOF

cat >"$hook_dir/pre-push" <<EOF
#!/bin/bash
expected_name="$personal_git_name"
expected_email="$personal_git_email"
actual_name="\$(git config user.name)"
actual_email="\$(git config user.email)"
if [ "\$actual_name" != "\$expected_name" ] || [ "\$actual_email" != "\$expected_email" ]; then
  echo "BLOCKED: dotfiles repo push identity (\$actual_name <\$actual_email>) != expected (\$expected_name <\$expected_email>)" >&2
  exit 1
fi
remote="\$(git config remote.origin.url)"
case "\$remote" in
  git@github.com:*) ;;
  *) echo "BLOCKED: origin is not the SSH URL (\$remote)" >&2; exit 1 ;;
esac
key="\$(git config core.sshCommand | sed -n 's/.*-i \([^ ]*\).*/\1/p')"
key="\${key/#\~/\$HOME}"
if [ -n "\$key" ] && [ ! -f "\$key" ]; then
  echo "BLOCKED: SSH key referenced by core.sshCommand not found: \$key" >&2
  exit 1
fi
EOF

chmod +x "$hook_dir/pre-commit" "$hook_dir/pre-push"

echo "Personal SSH identity configured for the dotfiles repo at $repo."
