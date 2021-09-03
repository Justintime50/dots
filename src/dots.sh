# shellcheck disable=SC1090,SC2148,SC2269

# User configurable variables
DOTFILES_DIR="$HOME/.dotfiles"
SHOW_INIT_MESSAGE="true"  # Leave this empty if you don't want to show the init messages (eg: SHOW_INIT_MESSAGE=)

# Dots required variables (do not edit)
DOTS_VERSION="v0.6.1"
HOSTNAME=$(hostname)  # Required for macOS
DOTS_SCRIPT="$DOTFILES_DIR/dots/src/dots.sh"
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"
DOTFILES_URL="$DOTFILES_URL"  # Yes, we recursively set this here because of our loop sourcing
DOTFILES_GITHUB_USER="$(basename "$(dirname "$DOTFILES_URL")")"  # Dynamically fill this based on the dotfiles URL

# TODO: Add a function that allows you to see what dotfiles were linked

# Checks that dotfiles are up to date each time a terminal starts
dots_get_dotfiles_status() {
    if [ -d "$DOTFILES_DIR" ] ; then
        dots_status
    else
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Ensures the dotfiles directory exists
dots_check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR" ] ; then
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Ensures the shell being used is supported
dots_check_shell() {
    if [ "$SHELL" != "/bin/zshs" ] && [ "$SHELL" != "/bin/bash" ] ; then
        echo "Dots doesn't support $SHELL."
        return 1
    fi
}

# Ensures the Dots config file is present
dots_check_config_file() {
    if [ ! -f "$DOTS_CONFIG_FILE" ] ; then
        echo "Dots couldn't find $DOTS_CONFIG_FILE."
        return 1
    fi
}

# Anything that Dots needs upon initialization goes here
dots_init() {
    dots_check_shell && (
        if [ "$SHELL" = "/bin/zsh" ] ; then
        SHELL_CONFIG_FILE="$HOME/.zshrc"
        elif [ "$SHELL" = "/bin/bash" ] ; then
        SHELL_CONFIG_FILE="$HOME/.bash_profile"
        fi
    )
}

# Print Dotfiles message on each shell start (will be initialized from core shell file)
dots_init_message() {
    echo "################### Dots $DOTS_VERSION ###################"
    echo "Shell: $SHELL"
    echo "Hostname: $HOSTNAME"
    echo "Powered by $DOTFILES_GITHUB_USER's Dotfiles"
    echo ""
    echo "Dotfiles status: "
    dots_get_dotfiles_status
    echo "###################################################"
}

# Push Dotfiles up to the Git server
dots_push() {
    dots_check_dotfiles_dir && (
        echo "Pushing dotfiles..."
        git -C "$DOTFILES_DIR" add .
        git -C "$DOTFILES_DIR" commit -m "Updated dotfiles"
        git -C "$DOTFILES_DIR" push > /dev/null 2>&1 && echo "Dotfiles pushed!" || echo "Error pushing Dotfiles"
    )
}

# Pull updates from the Dotfiles project
dots_pull() {	
    dots_check_dotfiles_dir && (
        echo "Pulling dotfiles..."
        git -C "$DOTFILES_DIR" pull --rebase > /dev/null 2>&1 && echo "Dotfiles pulled!" || echo "Error pulling Dotfiles"
    )
}

# Resets the .zshrc/.bash_profile files to only contain Dots and the config
dots_reset_terminal_config() {
    dots_init && (
        {
            echo "# Dots Config";
            echo "DOTFILES_URL=\"$DOTFILES_URL\"";
            echo ". $DOTS_SCRIPT";
            echo ". $DOTS_CONFIG_FILE";
            echo "dots_init";
            if [ "$SHOW_INIT_MESSAGE" ] ; then
                echo "dots_init_message";
            fi
            echo "";
            echo "# Dotfiles Config";
        } > "$SHELL_CONFIG_FILE"
    )
}

# Installs dotfiles based on the Dots config file
dots_install() {
    dots_check_config_file && (
        dots_reset_terminal_config
        echo "Installing dotfiles..."

        # The `dots_config_up` command is sourced from "$DOTS_CONFIG_FILE":
        dots_config_up && echo "Dotfiles installed!" || echo "Error installing Dotfiles"
    )
}

# Cleans dotfiles based on the Dots config file
dots_clean() {
    dots_check_config_file && (
        dots_reset_terminal_config
        echo "Cleaning dotfiles..."

        # The `dots_config_down` command is sourced from "$DOTS_CONFIG_FILE":
        dots_config_down && echo "Dotfiles cleaned!" || echo "Error cleaning Dotfiles"
    )
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
    dots_init && (
        . "$SHELL_CONFIG_FILE"
        echo "Dotfiles sourced!"
    )
}
