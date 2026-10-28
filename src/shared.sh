# This file contains functions that are required for both the installer and Dots itself

# shellcheck disable=SC2148,SC2034

# Prints a path wrapped in single quotes so it can be safely written into a shell config file (handles spaces, quotes, `$`, etc)
_dots_quote() {
    printf "'%s'\n" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# Sets the SHELL_CONFIG_FILE variable based on the current shell in use
_dots_set_shell_config_file() {
    if [ "$SHELL" = "/bin/zsh" ]; then
        SHELL_CONFIG_FILE="$HOME/.zshrc"
    elif [ "$SHELL" = "/bin/bash" ]; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
    elif [ "$SHELL" = "/bin/sh" ] || [ "$SHELL" = "/bin/dash" ] || [ "$SHELL" = "/bin/ksh" ]; then
        SHELL_CONFIG_FILE="$HOME/.profile"
    fi
}
