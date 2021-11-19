#!/bin/sh

# shellcheck disable=SC1090

DOTFILES_DIR="$HOME/.dotfiles"

main() {
    # Sets SHELL_CONFIG_FILE for our use
    _dots_set_shell_config_file
    
    # Add Dots as a sourced script to your current shell config (running this install script will overwrite your shell config file)
    echo ". $DOTFILES_DIR/dots/src/dots.sh" >> "$SHELL_CONFIG_FILE"
    echo ". $DOTFILES_DIR/dots-config.sh" >> "$SHELL_CONFIG_FILE"

    . "$SHELL_CONFIG_FILE"
    dots_sync  # This is sourced from the SHELL_CONFIG_FILE
}

# Sets the SHELL_CONFIG_FILE variable based on the current shell in use
_dots_set_shell_config_file() {
    if [ "$SHELL" = "/bin/zsh" ] ; then
        SHELL_CONFIG_FILE="$HOME/.zshrc"
    elif [ "$SHELL" = "/bin/bash" ] ; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
    elif [ "$SHELL" = "/bin/sh" ] || [ "$SHELL" = "/bin/dash" ] || [ "$SHELL" = "/bin/ksh" ] ; then
        SHELL_CONFIG_FILE="$HOME/.profile"
    fi
}

main
