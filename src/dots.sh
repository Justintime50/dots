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
DOTS_SHELL_CONFIG_HEADER="# Dots Config (automatically set, do not edit)" # Always the first line of a shell config Dots writes

### CHECKERS ###

# Ensures the dotfiles directory exists
_dots_check_dotfiles_dir() {
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "Dotfiles directory does not exist."
        return 1
    fi
}

# Ensures the shell being used is supported, matched by name so any install location works (eg: `/opt/homebrew/bin/zsh`)
_dots_check_shell() {
    case "${SHELL##*/}" in
    zsh | bash | sh | dash | ksh) ;;
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

# Prints the contents of the shell config that Dots manages
_dots_print_terminal_config() {
    echo "$DOTS_SHELL_CONFIG_HEADER"
    printf '. %s\n' "$(_dots_quote "$DOTS_SCRIPT_FILE")"
    printf '. %s\n' "$(_dots_quote "$DOTS_CONFIG_FILE")"
    echo "_dots_init"
    if [ -z "$DOTS_DISABLE_INIT_MESSAGE" ]; then
        echo "_dots_init_message"
    fi
    echo ""
    echo "# Dotfiles Config (custom, edit below this line)"
}

# Succeeds if the shell config only loads Dots (eg: the line added by the install steps on a fresh machine)
# Every line must be blank, a comment, or `. <path>/dots.sh` / `source <path>/dots.sh`, so an empty file counts too
# The path is one double-quoted, single-quoted, or unquoted word, so a line that also runs something else isn't matched
_dots_shell_config_is_dots_only() {
    [ -r "$SHELL_CONFIG_FILE" ] &&
        ! grep -Evq -e '^[[:space:]]*(#.*)?$' \
            -e '^[[:space:]]*(\.|source)[[:space:]]+("([^"`(]*/)?dots\.sh"|'\''([^'\'']*/)?dots\.sh'\''|([^"'\''[:space:];&|<>()`\]*/)?dots\.sh)[[:space:]]*$' \
            "$SHELL_CONFIG_FILE"
}

# Backs up a shell config with the user's own setup (eg: on a machine with existing dotfiles) to `<file>.pre-dots`
# Nothing is backed up when there's no config, it's a symlink (the file it points to is left untouched), Dots wrote it, or it only loads Dots
# The first backup is never overwritten, a later config with the user's own setup gets a uniquely named timestamped backup instead
# This file is sourced, so variables are prefixed and unset to avoid leaking into the user's shell (no `local` in POSIX)
_dots_backup_terminal_config() {
    [ -f "$SHELL_CONFIG_FILE" ] && [ ! -L "$SHELL_CONFIG_FILE" ] || return 0
    [ "$(head -n 1 "$SHELL_CONFIG_FILE")" = "$DOTS_SHELL_CONFIG_HEADER" ] && return 0
    _dots_shell_config_is_dots_only && return 0
    _dots_rc_backup="$SHELL_CONFIG_FILE.pre-dots"
    if [ -e "$_dots_rc_backup" ]; then
        _dots_rc_backup_base="$_dots_rc_backup.$(date +%Y%m%d%H%M%S).$$"
        _dots_rc_backup="$_dots_rc_backup_base"
        _dots_rc_backup_count=1
        while [ -e "$_dots_rc_backup" ]; do
            _dots_rc_backup="$_dots_rc_backup_base.$_dots_rc_backup_count"
            _dots_rc_backup_count=$((_dots_rc_backup_count + 1))
        done
        unset _dots_rc_backup_base _dots_rc_backup_count
    fi
    if cp -p "$SHELL_CONFIG_FILE" "$_dots_rc_backup"; then
        printf 'Backed up %s to %s\n' "$SHELL_CONFIG_FILE" "$_dots_rc_backup"
        unset _dots_rc_backup
        return 0
    fi
    unset _dots_rc_backup
    return 1
}

# Resets the `~/.zshrc`, `~/.bash_profile`, or `~/.profile` file to only contain Dots and the config, creating it if it doesn't exist
# The new file is written beside the old one and then moved into place, so a failure leaves the old file untouched
# A symlinked shell config is replaced with a regular file rather than written through, so the file it points to is left alone
_dots_reset_terminal_config() {
    _dots_init || return 1
    _dots_check_config_file || return 1
    _dots_rc_tmp="$SHELL_CONFIG_FILE.dots-tmp.$$"
    # Copying the existing file first keeps its permissions
    if { [ ! -f "$SHELL_CONFIG_FILE" ] || cp -p "$SHELL_CONFIG_FILE" "$_dots_rc_tmp"; } &&
        _dots_print_terminal_config >"$_dots_rc_tmp" &&
        _dots_backup_terminal_config &&
        mv -f "$_dots_rc_tmp" "$SHELL_CONFIG_FILE"; then
        unset _dots_rc_tmp
        return 0
    fi
    rm -f "$_dots_rc_tmp"
    printf "Dots couldn't update %s, it was left unchanged\n" "$SHELL_CONFIG_FILE" >&2
    unset _dots_rc_tmp
    return 1
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

# Ensure there are no uncommitted changes (including submodule pointer updates) that a pull would silently revert
# Edits inside a submodule's own working tree are ignored as a pull doesn't touch them
_dots_check_clean_tree() {
    git -C "$DOTFILES_DIR" diff --quiet --ignore-submodules=dirty HEAD -- 2>>"$DOTS_HOME_DIR/sync.log" && return 0
    echo "Uncommitted changes in $DOTFILES_DIR (including submodule updates), commit them with dots_push or dots_sync before pulling" | tee -a "$DOTS_HOME_DIR/sync.log" >&2
    return 1
}

# Succeeds if a rebase is in progress or there are unmerged files in the dotfiles repo
# This file is sourced, so variables are prefixed and unset to avoid leaking into the user's shell (no `local` in POSIX)
_dots_has_conflict() {
    _dots_git_dir="$(git -C "$DOTFILES_DIR" rev-parse --absolute-git-dir 2>>"$DOTS_HOME_DIR/sync.log")"
    if [ -n "$_dots_git_dir" ] && { [ -d "$_dots_git_dir/rebase-merge" ] || [ -d "$_dots_git_dir/rebase-apply" ]; }; then
        unset _dots_git_dir
        return 0
    fi
    unset _dots_git_dir
    [ -n "$(git -C "$DOTFILES_DIR" ls-files -u 2>>"$DOTS_HOME_DIR/sync.log")" ]
}

# Stage and commit local changes, if any
_dots_commit() {
    _dots_git rev-parse --git-dir || return 1
    if _dots_has_conflict; then
        echo "A rebase or merge conflict is unresolved in $DOTFILES_DIR, resolve it before syncing" | tee -a "$DOTS_HOME_DIR/sync.log" >&2
        return 1
    fi
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
    _dots_reset_terminal_config || return 1
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
    _dots_reset_terminal_config || return 1
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
# Dotfiles are still installed and sourced if a git step fails (eg: offline) unless a rebase or merge conflict is unresolved
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
        # Never install from a half-rebased or conflicted tree
        _dots_has_conflict && return 1
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
