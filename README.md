# dotfiles

Personal macOS (Apple Silicon) dotfiles, managed with [chezmoi](https://www.chezmoi.io).

## Prerequisites

This setup does **not** install Homebrew, chezmoi, or the Command Line Tools for you — they
must exist first:

1. **Xcode Command Line Tools** — `xcode-select --install` (also pulled in by the Homebrew installer).
2. **Homebrew** — <https://brew.sh>.
3. **chezmoi** — `brew install chezmoi`.

Everything else (packages, casks, fonts, runtimes, tmux plugin manager, shell setup) is handled
by chezmoi on first apply.

## Bootstrap

```sh
chezmoi init --apply https://github.com/eriklindebratt/dotfiles.git
```

HTTPS is used so this works on a fresh machine before SSH is set up. On apply, chezmoi will:

- deploy the dotfiles (zsh, git, nvim, tmux, starship, ghostty, ripgrep, Claude Code, `~/bin` scripts);
- install Homebrew packages from the `Brewfile`;
- install the mise-managed runtimes from `~/.tool-versions` (prompted);
- optionally apply macOS defaults from `.macos` (prompted);
- prompt for your global Git identity (stored in `~/.gitconfig.local`);
- optionally set up a personal SSH key/identity + `github-personal` ssh alias for this repo (prompted).

Each prompted step is skipped automatically when run without a TTY (CI, piped).

## What's managed

| Area | Source | Target |
|---|---|---|
| zsh | `dot_zshrc` | `~/.zshrc` |
| git | `dot_gitconfig`, `dot_gitignore`, `dot_gitattributes` | `~/.gitconfig`, `~/.gitignore`, `~/.gitattributes` |
| nvim | `dot_config/nvim/` | `~/.config/nvim/` |
| tmux | `dot_config/tmux/` + tpm (chezmoi external) | `~/.config/tmux/` |
| starship | `dot_config/starship.toml` | `~/.config/starship.toml` |
| ghostty | `dot_config/ghostty/config` | `~/.config/ghostty/config` |
| ripgrep | `dot_ripgreprc`, `dot_rgignore` | `~/.ripgreprc`, `~/.rgignore` |
| Claude Code | `dot_claude/` | `~/.claude/settings.json`, `~/.claude/statusline.sh` |
| scripts | `bin/` | `~/bin/` |

`Brewfile`, `.macos`, and this `README.md` live in the repo but are not deployed to `$HOME`
(`.macos` is sourced by the macOS-defaults script).

## Git identity & personal SSH

Your **global** Git name/email are written to `~/.gitconfig.local` (prompted on first apply,
re-prompted if that file goes missing); `~/.gitconfig` includes it. Because `~/.gitconfig.local`
is not managed by chezmoi, later edits stick and aren't reverted by `chezmoi apply`.

`run_once_setup-ssh.sh` optionally configures a **personal** SSH key + identity for *this dotfiles
repo only*. It writes the identity and key choice to the repo's `.git/config`, ensures a
`Host github-personal` alias block in `~/.ssh/config` (so only the personal key is ever offered to
GitHub — even on machines whose `Host github.com` entry carries another identity), rewrites a
github.com origin (HTTPS or SSH) to `git@github-personal:<owner>/<repo>.git`, and installs
`pre-commit` / `pre-push` hooks that block commits/pushes made under the wrong identity, via a
non-alias remote, or via an alias that no longer resolves to github.com with the recorded key. A
pre-existing `Host github-personal` block pointing at a different key is never modified — the
script warns and the `pre-push` hook blocks pushes until you point its `IdentityFile` at the
selected key.

When the repo is already set up (`hooks.sshKey` set and the key exists), re-runs — after this
script's contents change, or a manual invocation — offer to set it up again instead of running
full setup: make sure commits/pushes use your personal Git identity, and route origin through the
`github-personal` alias (rewriting origin and editing `~/.ssh/config`). It does this only after an
interactive y/N; with no controlling terminal (CI, piped, cron) it does nothing and leaves
everything untouched — nothing is modified without a confirmation. It is also **not** drift
recovery: chezmoi only re-runs a `run_once_` script when its *contents* change, so deleting the
alias block or `.git/hooks` won't trigger it on its own — the `pre-push` hook blocks until you
re-run the script.

> **Manual-clone caveat:** git never runs hooks from a freshly cloned repo, and `.git/hooks` is
> not part of a clone — so the identity-guard hooks exist only after `setup-ssh` runs during an
> apply. If you manually clone and commit *before* running it, no personal identity is configured
> and the hooks aren't installed (worst case: you commit under your global identity). Re-running
> `setup-ssh` (or `chezmoi apply`) installs them.
