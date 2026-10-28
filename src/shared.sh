# This file contains functions that are required for both the installer and Dots itself

# shellcheck disable=SC2148,SC2034

# Prints a path wrapped in single quotes so it can be safely written into a shell config file (handles spaces, quotes, `$`, etc)
_dots_quote() {
    printf "'%s'\n" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

# Sets the SHELL_CONFIG_FILE variable based on the name of the current shell in use (any install location)
_dots_set_shell_config_file() {
    case "${SHELL##*/}" in
    zsh) SHELL_CONFIG_FILE="$HOME/.zshrc" ;;
    bash) SHELL_CONFIG_FILE="$HOME/.bash_profile" ;;
    sh | dash | ksh) SHELL_CONFIG_FILE="$HOME/.profile" ;;
    *) return 1 ;;
    esac
}
