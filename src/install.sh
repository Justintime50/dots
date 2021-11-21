#!/bin/sh

# This script will install Dots initially on your system

# shellcheck disable=SC1090

DOTFILES_DIR="$HOME/.dotfiles"

main() {
    # Sets SHELL_CONFIG_FILE for our use
    . shared.sh
    _dots_set_shell_config_file  # Sourced from `shared.sh`
    
    # Add Dots as a sourced script to your current shell config (running this install script will overwrite your shell config file)
    echo ". $DOTFILES_DIR/dots/src/dots.sh" >> "$SHELL_CONFIG_FILE"
    echo ". $DOTFILES_DIR/dots-config.sh" >> "$SHELL_CONFIG_FILE"

    # Source the SHELL_CONFIG_FILE so we can call `dots_sync`
    . "$SHELL_CONFIG_FILE"
    dots_sync
}

main
