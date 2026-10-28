# Dots: The simple, flexible, Dotfile manager.

# shellcheck disable=SC1090,SC1091,SC2148

# User configurable variables (must remain in this file)
DOTFILES_DIR="$HOME/.dotfiles" # Cannot be `~/.dots` as we will use this for internal Dots usage
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"

# Dots required variables (DO NOT EDIT)
DOTS_VERSION="v2.1.0"
HOSTNAME="$(hostname)" # Required for macOS as it's not set automatically like it is on Linux
DOTS_HOME_DIR="$HOME/.dots"
DOTS_DIR="$DOTFILES_DIR/dots/src"
DOTS_SCRIPT_FILE="$DOTS_DIR/dots.sh"

### CHECKERS ###

# Ensures the dotfiles directory exists
_dots_check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Ensures the shell being used is supported
_dots_check_shell() {
    if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/bin/bash" ] && [ "$SHELL" != "/bin/sh" ] && [ "$SHELL" != "/bin/dash" ] && [ "$SHELL" = "/bin/ksh" ]; then
        echo "Dots doesn't support $SHELL."
        return 1
    fi
}

# Ensures the Dots config file exists
_dots_check_config_file() {
    if [ ! -f "$DOTS_CONFIG_FILE" ]; then
        echo "Dots couldn't find DOTS_CONFIG_FILE."
        return 1
    fi
}

# Ensures the shell config file exists
_dots_check_shell_config_file() {
    if [ ! -f "$SHELL_CONFIG_FILE" ]; then
        echo "Dots couldn't find SHELL_CONFIG_FILE."
        return 1
    fi
}

### HELPERS ###

# Checks that dotfiles are up to date each time a terminal starts
_dots_get_dotfiles_status() {
    if _dots_check_dotfiles_dir; then
        dots_status
    else
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Anything that Dots needs upon initialization goes here
_dots_init() {
    if _dots_check_shell; then
        # Source anything that's required for the installer and dots such as `_dots_set_shell_config_file`
        . "$DOTS_DIR/shared.sh"
        _dots_set_shell_config_file

        mkdir -p "$DOTS_HOME_DIR"
    else
        return 1
    fi
}

# Print Dotfiles message on each shell start (will be initialized from core shell file)
_dots_init_message() {
    echo "################ Dots $DOTS_VERSION ################"
    echo "Shell: $SHELL"
    echo "Hostname: $HOSTNAME" # We print Hostname here to assist with multi-machine Dotfile management
    if [ -z "$DOTS_DISABLE_DOTFILES_STATUS" ]; then
        echo ""
        echo "Dotfiles status:"
        _dots_get_dotfiles_status
    fi
    echo "#############################################"
}

# Resets the `~/.zshrc`, `~/.bash_profile`, or `~/.profile` files to only contain Dots and the config
# Be aware this will overwrite whatever the user has setup at those locations and create it if it doesn't exist
_dots_reset_terminal_config() {
    if _dots_init; then
        {
            echo "# Dots Config (automatically set, do not edit)"
            echo ". $DOTS_SCRIPT_FILE"
            echo ". $DOTS_CONFIG_FILE"
            echo "_dots_init"
            if [ -z "$DOTS_DISABLE_INIT_MESSAGE" ]; then
                echo "_dots_init_message"
            fi
            echo ""
            echo "# Dotfiles Config (custom, edit below this line)"
        } >"$SHELL_CONFIG_FILE" # If this file doesn't yet exist, it will be created here
    fi
}

# Save the installation steps to a log
_dots_log_install_step() {
    # The `dots_config_up` command is sourced from "$DOTS_CONFIG_FILE":
    {
        set -x
        dots_config_up
        set +x
    } 2>"$DOTS_HOME_DIR/install.log"
}

# Save the clean steps to a log
_dots_log_clean_step() {
    # The `dots_config_down` command is sourced from "$DOTS_CONFIG_FILE":
    {
        set -x
        dots_config_down
        set +x
    } 2>"$DOTS_HOME_DIR/clean.log"
}

### GIT ###

# Run a git command in the dotfiles repo quietly, logging output for debugging
_dots_git() {
    mkdir -p "$DOTS_HOME_DIR"
    git -C "$DOTFILES_DIR" "$@" >>"$DOTS_HOME_DIR/sync.log" 2>&1
}

# Start a fresh git log for this run
_dots_reset_sync_log() {
    mkdir -p "$DOTS_HOME_DIR" && : >"$DOTS_HOME_DIR/sync.log"
}

# Ensure there are no uncommitted changes (including submodule updates) that a pull would silently revert
_dots_check_clean_tree() {
    git -C "$DOTFILES_DIR" diff --quiet --ignore-submodules=untracked HEAD -- 2>>"$DOTS_HOME_DIR/sync.log" && return 0
    echo "Uncommitted changes in $DOTFILES_DIR (including submodule updates), commit them with dots_push or dots_sync before pulling" | tee -a "$DOTS_HOME_DIR/sync.log" >&2
    return 1
}

# Stage and commit local changes, if any
# This file is sourced, so variables are prefixed and unset to avoid leaking into the user's shell (no `local` in POSIX)
_dots_commit() {
    if ! _dots_git_dir="$(git -C "$DOTFILES_DIR" rev-parse --absolute-git-dir 2>>"$DOTS_HOME_DIR/sync.log")"; then
        unset _dots_git_dir
        return 1
    fi
    if [ -d "$_dots_git_dir/rebase-merge" ] || [ -d "$_dots_git_dir/rebase-apply" ] || [ -n "$(git -C "$DOTFILES_DIR" ls-files -u)" ]; then
        unset _dots_git_dir
        echo "A rebase or merge conflict is unresolved in $DOTFILES_DIR, resolve it before syncing" | tee -a "$DOTS_HOME_DIR/sync.log" >&2
        return 1
    fi
    unset _dots_git_dir
    _dots_git add -A || return 1
    _dots_git diff --cached --quiet && return 0
    _dots_git commit -m "Updated dotfiles"
}

### INTERFACES ###

# Push Dotfiles up to the Git server
dots_push() {
    _dots_check_dotfiles_dir || return 1
    _dots_reset_sync_log
    echo "Pushing dotfiles..."
    if _dots_commit && _dots_git push; then
        echo "Dotfiles pushed!"
    else
        echo "Error pushing Dotfiles, see $DOTS_HOME_DIR/sync.log"
        return 1
    fi
}

# Pull updates from the Dotfiles project
dots_pull() {
    _dots_check_dotfiles_dir || return 1
    _dots_reset_sync_log
    echo "Pulling dotfiles..."
    if _dots_check_clean_tree &&
        _dots_git pull --rebase &&
        _dots_git submodule update --init --recursive; then
        echo "Dotfiles pulled!"
    else
        echo "Error pulling Dotfiles, see $DOTS_HOME_DIR/sync.log"
        return 1
    fi
}

# Installs dotfiles based on the Dots config file
dots_install() {
    _dots_check_config_file || return 1
    _dots_reset_terminal_config
    echo "Installing dotfiles..."
    if _dots_log_install_step; then
        echo "Dotfiles installed!"
    else
        echo "Error installing Dotfiles"
        return 1
    fi
}

# Cleans dotfiles based on the Dots config file
dots_clean() {
    _dots_check_config_file || return 1
    _dots_reset_terminal_config
    echo "Cleaning dotfiles..."
    if _dots_log_clean_step; then
        echo "Dotfiles cleaned!"
    else
        echo "Error cleaning Dotfiles"
        return 1
    fi
}

# Gets the status of dotfiles
dots_status() {
    # Fetch the changes in the background (subprocess) to avoid locking the terminal, will show updates on next run
    (git -C "$DOTFILES_DIR" fetch --recurse-submodules=on-demand >/dev/null 2>&1 &)
    git -C "$DOTFILES_DIR" status -sb || echo "Couldn't check remote Dotfiles"
}

# Gets the diff of dotfiles
dots_diff() {
    git -C "$DOTFILES_DIR" diff
}

# Syncs dotfiles from your local machine to and from your dotfiles repo
# Commits local changes first, then rebases onto the remote, then pushes, stopping at the first failed git step
# Dotfiles are installed and sourced even if a git step fails (eg: offline), but the failure is still reported
dots_sync() {
    _dots_check_dotfiles_dir || return 1
    _dots_reset_sync_log
    echo "Syncing dotfiles..."
    if _dots_commit &&
        _dots_git pull --rebase &&
        _dots_git submodule update --init --recursive &&
        _dots_git push; then
        echo "Dotfiles synced!"
        dots_install && dots_source
    else
        echo "Error syncing Dotfiles, see $DOTS_HOME_DIR/sync.log"
        dots_install && dots_source
        return 1
    fi
}

# Sources the shell
dots_source() {
    if _dots_init && _dots_check_shell_config_file; then
        . "$SHELL_CONFIG_FILE"
        echo "Dotfiles sourced!"
    fi
}

# List the dotfiles that were installed
dots_list() {
    cat "$DOTS_HOME_DIR/install.log"
}

# Update the Dots submodule in the `DOTFILES_DIR`
dots_update() {
    if _dots_check_dotfiles_dir; then
        git -C "$DOTFILES_DIR" submodule update --remote dots
    fi
}
