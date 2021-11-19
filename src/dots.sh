# Dots: The simple, flexible, Dotfile manager.
# shellcheck disable=SC1090,SC2148

# User configurable variables
DOTFILES_DIR="$HOME/.dotfiles"  # Cannot be `~/.dots` as we will use this for internal Dots usage
DOTS_SHOW_INIT_MESSAGE="true"  # Leave this empty if you don't want to show the init messages (eg: DOTS_SHOW_INIT_MESSAGE=)

# Dots required variables (do not edit)
DOTS_VERSION="v1.0.0"
DOTS_DIR="$HOME/.dots"
HOSTNAME="$(hostname)"  # Required for macOS as it's not set automatically like it is on Linux
DOTS_SCRIPT_FILE="$DOTFILES_DIR/dots/src/dots.sh"
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"

### CHECKERS ###

# Ensures the dotfiles directory exists
_dots_check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR" ] ; then
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Ensures the shell being used is supported
_dots_check_shell() {
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/bin/bash" ] && [ "$SHELL" != "/bin/sh" ] && [ "$SHELL" != "/bin/dash" ] && [ "$SHELL" = "/bin/ksh" ] ; then
        echo "Dots doesn't support $SHELL."
        return 1
    fi
}

# Ensures the Dots config file exists
_dots_check_config_file() {
    if [ ! -f "$DOTS_CONFIG_FILE" ] ; then
        echo "Dots couldn't find DOTS_CONFIG_FILE."
        return 1
    fi
}

# Ensures the shell config file exists
_dots_check_shell_config_file() {
    if [ ! -f "$SHELL_CONFIG_FILE" ] ; then
        echo "Dots couldn't find SHELL_CONFIG_FILE."
        return 1
    fi
}

### HELPERS ###

# Checks that dotfiles are up to date each time a terminal starts
_dots_get_dotfiles_status() {
    if _dots_check_dotfiles_dir ; then
        dots_status
    else
        echo "Dotfiles directory does not exist."
        return 1
    fi
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

# Anything that Dots needs upon initialization goes here
_dots_init() {
    if _dots_check_shell ; then
        mkdir -p "$DOTS_DIR"
        _dots_set_shell_config_file
    else
        return 1
    fi
}

# Print Dotfiles message on each shell start (will be initialized from core shell file)
_dots_init_message() {
    echo "################### Dots $DOTS_VERSION ###################"
    echo "Shell: $SHELL"
    echo "Hostname: $HOSTNAME"  # We print Hostname here to assist with multi-machine Dotfile management
    echo ""
    echo "Dotfiles status:"
    _dots_get_dotfiles_status
    echo "###################################################"
}

# Resets the `~/.zshrc`, `~/.bash_profile`, or `~/.profile` files to only contain Dots and the config
# Be aware this will overwrite whatever the user has setup at those locations and create it if it doesn't exist
_dots_reset_terminal_config() {
    if _dots_init ; then
        {
            echo "# Dots Config";
            echo ". $DOTS_SCRIPT_FILE";
            echo ". $DOTS_CONFIG_FILE";
            echo "_dots_init";
            if [ "$DOTS_SHOW_INIT_MESSAGE" ] ; then
                echo "_dots_init_message";
            fi
            echo "";
            echo "# Dotfiles Config";
        } > "$SHELL_CONFIG_FILE"  # If this file doesn't yet exist, it will be created here
    fi
}

# Save the installation steps to a log
_dots_log_install_step() {
    # The `dots_config_up` command is sourced from "$DOTS_CONFIG_FILE":
    { set -x; dots_config_up; set +x; } 2> "$DOTS_DIR/install.log"    
}

# Save the clean steps to a log
_dots_log_clean_step() {
    # The `dots_config_down` command is sourced from "$DOTS_CONFIG_FILE":
    { set -x; dots_config_down; set +x; } 2> "$DOTS_DIR/clean.log"    
}

### INTERFACES ###

# Push Dotfiles up to the Git server
dots_push() {
    if _dots_check_dotfiles_dir ; then
        echo "Pushing dotfiles..."
        git -C "$DOTFILES_DIR" add .
        git -C "$DOTFILES_DIR" commit -m "Updated dotfiles"
        git -C "$DOTFILES_DIR" push > /dev/null 2>&1 && echo "Dotfiles pushed!" || echo "Error pushing Dotfiles"
    fi
}

# Pull updates from the Dotfiles project
dots_pull() {
    if _dots_check_dotfiles_dir ; then
        echo "Pulling dotfiles..."
        git -C "$DOTFILES_DIR" pull --rebase > /dev/null 2>&1 && echo "Dotfiles pulled!" || echo "Error pulling Dotfiles"
    fi
}

# Installs dotfiles based on the Dots config file
dots_install() {
    if _dots_check_config_file ; then
        _dots_reset_terminal_config
        echo "Installing dotfiles..."
        _dots_log_install_step && echo "Dotfiles installed!" || echo "Error installing Dotfiles"
    fi
}

# Cleans dotfiles based on the Dots config file
dots_clean() {
    echo "Dots is about to clean your Dotfiles. Press any key to continue."
    read -r

    if _dots_check_config_file ; then
        _dots_reset_terminal_config
        echo "Cleaning dotfiles..."
        _dots_log_clean_step && echo "Dotfiles cleaned!" || echo "Error cleaning Dotfiles"
    fi
}

# Gets the status of dotfiles
dots_status() {
    git -C "$DOTFILES_DIR" remote update > /dev/null 2>&1 || echo "Error updating from remote Dotfiles"
    git -C "$DOTFILES_DIR" status -s -b || echo "Couldn't check remote Dotfiles"
}

# Syncs dotfiles from your local machine to and from your dotfiles repo
dots_sync() {
    echo "Dots is about to sync your Dotfiles, this process may override your current Dotfiles. Press any key to continue."
    read -r

    dots_pull
    dots_push
    dots_install
    dots_source
}

# Sources the shell
dots_source() {
    if _dots_init && _dots_check_shell_config_file ; then
        . "$SHELL_CONFIG_FILE"
        echo "Dotfiles sourced!"
    fi
}

# List the dotfiles that were installed
dots_list() {
    cat "$DOTS_DIR/install.log"
}
