#!/bin/bash
# Ensure the login shell is zsh. macOS has defaulted to zsh since Catalina, so this
# is usually a no-op. Uses the system zsh (/bin/zsh), already listed in /etc/shells.

case "$SHELL" in
  */zsh) exit 0 ;;
esac

# chezmoi does not attach the terminal to a script's stdin; prompt via /dev/tty.
if ! { : </dev/tty; } 2>/dev/null; then
  echo "No terminal; login shell is $SHELL. Run 'chsh -s /bin/zsh' later to switch."
  exit 0
fi

read -r -p "Login shell is $SHELL, not zsh. Switch to /bin/zsh? (y/N) " response </dev/tty
case "$response" in
  [yY][eE][sS]|[yY])
    chsh -s /bin/zsh && echo "Login shell set to /bin/zsh — restart your session for it to take effect."
    ;;
  *)
    echo "Leaving login shell as $SHELL."
    ;;
esac
