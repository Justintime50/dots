#!/bin/sh

# This script will install Dots initially on your system

# shellcheck disable=SC1090,SC1091

main() {
    # Sources various variables needed for this script
    . "$DOTS_DIR/shared.sh"
    _dots_set_shell_config_file # Sourced from `shared.sh`

    # Add Dots as a sourced script to your current shell config (running this install script will overwrite your shell config file)
    echo ". $DOTS_DIR/dots.sh" >>"$SHELL_CONFIG_FILE"
    echo ". $DOTS_CONFIG_FILE" >>"$SHELL_CONFIG_FILE"

    # Source the SHELL_CONFIG_FILE so we can call `dots_sync`
    . "$SHELL_CONFIG_FILE"
    dots_sync
}

main
