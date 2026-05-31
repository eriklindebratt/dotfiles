#!/bin/bash
# Ensure the login shell is zsh. macOS has defaulted to zsh since Catalina, so this
# is usually a no-op. Uses the system zsh (/bin/zsh), already listed in /etc/shells.

case "$SHELL" in
  */zsh) exit 0 ;;
esac

if [ ! -t 0 ]; then
  echo "No TTY; login shell is $SHELL (not zsh). Run 'chsh -s /bin/zsh' later to switch."
  exit 0
fi

read -r -p "Login shell is $SHELL, not zsh. Switch to /bin/zsh? (y/N) " response
case "$response" in
  [yY][eE][sS]|[yY])
    chsh -s /bin/zsh && echo "Login shell set to /bin/zsh — restart your session for it to take effect."
    ;;
  *)
    echo "Leaving login shell as $SHELL."
    ;;
esac
