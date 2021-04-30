#!/bin/bash

# shellcheck disable=SC1090

DOTFILES_DIR="$HOME/.dotfiles"
SHELL_CONFIG_FILE="$HOME/$2"

main() {
    if [[ -z "$1" && -z "$2" ]] ; then
        # Add Dots as a sourced script to your current shell config
        echo ". $DOTFILES_DIR/dots/src/dots.sh" >> "$SHELL_CONFIG_FILE"
        echo ". $DOTFILES_DIR/dots-config.sh" >> "$SHELL_CONFIG_FILE"

        # Run `dots_sync` the first time specifying the DOTFILES_URL of your project (replace USERNAME)
        . "$SHELL_CONFIG_FILE"
        DOTFILES_URL="$1" dots_sync
    else
        echo "Could not install Dots due to missing parameters."
        exit 1
    fi
}

main "$@"
