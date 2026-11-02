# Dots: The simple, flexible, Dotfile manager.

# shellcheck disable=SC1090,SC1091,SC2148

# User configurable variables (must remain in this file)
DOTFILES_DIR="$HOME/.dotfiles" # Cannot be `~/.dots` as we will use this for internal Dots usage
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"

# Dots required variables (DO NOT EDIT)
DOTS_VERSION="v3.0.0"
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

# Ensures the shell being used is supported, matched by name so any install location works
_dots_check_shell() {
    case "${SHELL##*/}" in
    zsh | bash | sh) ;;
    *)
        echo "Dots doesn't support $SHELL."
        return 1
        ;;
    esac
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

# Run a git command in the dotfiles repo quietly, logging output to `~/.dots/sync.log`
_dots_git() {
    git -C "$DOTFILES_DIR" "$@" >>"$DOTS_HOME_DIR/sync.log" 2>&1
}

# Start a fresh git log for this run
_dots_reset_sync_log() {
    mkdir -p "$DOTS_HOME_DIR" && : >"$DOTS_HOME_DIR/sync.log"
}

# Succeeds if any of the given git state files exist (eg: `rebase-merge`), resolved with `--git-path` so worktrees and submodules work
_dots_git_state() {
    (cd "$DOTFILES_DIR" && for _dots_path in "$@"; do [ -e "$(git rev-parse --git-path "$_dots_path")" ] && exit 0; done && exit 1)
}

# Ensures no rebase or merge is already in progress, which is left untouched
_dots_check_no_rebase() {
    _dots_git_state rebase-merge rebase-apply MERGE_HEAD || return 0
    echo "A rebase or merge is in progress in $DOTFILES_DIR, finish it first"
    return 1
}

# Stage and commit local changes, if any
_dots_commit() {
    _dots_check_no_rebase || return 1
    _dots_git add . || return 1
    _dots_git diff --cached --quiet && return 0
    _dots_git commit -m "Updated dotfiles"
}

# Pull with a rebase, a failed rebase is aborted so the repo is never left mid-rebase
_dots_pull_rebase() {
    _dots_git pull --rebase && return 0
    _dots_git_state rebase-merge rebase-apply && _dots_git rebase --abort
    return 1
}

# Update submodules that are already checked out to their recorded commits, skipping any that were never checked out
_dots_update_submodules() {
    _dots_git submodule foreach --quiet --recursive 'git -C "$toplevel" submodule update -- "$sm_path"'
}

# Update submodules, then push even if that update failed so local commits still go up
_dots_update_and_push() {
    _dots_update_submodules || {
        _dots_git push
        return 1
    }
    _dots_git push
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
    _dots_check_no_rebase || return 1
    if ! git -C "$DOTFILES_DIR" diff --quiet --ignore-submodules=dirty HEAD; then
        echo "Uncommitted changes in $DOTFILES_DIR (including submodule updates), commit them with dots_push or dots_sync first"
        return 1
    fi
    echo "Pulling dotfiles..."
    if _dots_pull_rebase && _dots_update_submodules; then
        echo "Dotfiles pulled!"
    else
        echo "Error pulling Dotfiles, see $DOTS_HOME_DIR/sync.log"
        return 1
    fi
}

# Installs dotfiles based on the Dots config file
dots_install() {
    if _dots_check_config_file; then
        _dots_reset_terminal_config
        echo "Installing dotfiles..."
        _dots_log_install_step && echo "Dotfiles installed!" || echo "Error installing Dotfiles"
    fi
}

# Cleans dotfiles based on the Dots config file
dots_clean() {
    if _dots_check_config_file; then
        _dots_reset_terminal_config
        echo "Cleaning dotfiles..."
        _dots_log_clean_step && echo "Dotfiles cleaned!" || echo "Error cleaning Dotfiles"
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
# Commits local changes, rebases onto the remote, updates submodules, then pushes, stopping at the first failed git step (a failed submodule update still pushes)
# Dotfiles are installed and sourced either way (eg: when offline)
dots_sync() {
    _dots_check_dotfiles_dir || return 1
    _dots_reset_sync_log
    echo "Syncing dotfiles..."
    if _dots_commit && _dots_pull_rebase && _dots_update_and_push; then
        echo "Dotfiles synced!"
        dots_install
        dots_source
    else
        echo "Error syncing Dotfiles, see $DOTS_HOME_DIR/sync.log"
        dots_install
        dots_source
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
