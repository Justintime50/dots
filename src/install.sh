#!/bin/sh

# This script will install Dots initially on your system

# shellcheck disable=SC1090,SC1091

# These vars must remain in this file
DOTFILES_DIR="$HOME/.dotfiles"
DOTS_DIR="$DOTFILES_DIR/dots/src"
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"

main() {
    # Load Dots, which writes your shell config the same way `dots_install` does
    . "$DOTS_DIR/dots.sh"

    # Replace your shell config with one that loads Dots and your config (an existing one is backed up to `<file>.pre-dots`)
    # Nothing is changed if the shell is unsupported, your dotfiles or config are missing, or the new file can't be written
    _dots_check_dotfiles_dir || exit 1
    _dots_reset_terminal_config || exit 1

    # Load your config so we can call `dots_sync`
    . "$DOTS_CONFIG_FILE"
    dots_sync
}

main
