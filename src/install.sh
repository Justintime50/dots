#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"

main() {
    if [[ -z "$1" && -z "$2" ]] ; then
        # Add Dots as a sourced script to your current shell config
        echo ". $DOTFILES_DIR/dots/src/dots.sh" >> "$HOME/$2"
        echo ". $DOTFILES_DIR/dots-config.sh" >> "$HOME/$2"

        # Run `dots_sync` the first time specifying the DOTFILES_URL of your project (replace USERNAME)
        exec "$SHELL"
        DOTFILES_URL="$1" dots_sync
    else
        echo "Could not install Dots due to missing parameters."
        exit 1
}

main
