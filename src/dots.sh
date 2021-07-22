# shellcheck disable=SC1090,SC2148,SC2269

# User configurable variables
DOTFILES_DIR="$HOME/.dotfiles"
SHOW_INIT_MESSAGE="true" # Leave this empty if you don't want to show the init messages (eg: SHOW_INIT_MESSAGE=)

# Dots required variables (do not edit)
DOTS_VERSION="v0.5.0"
HOSTNAME=$(hostname) # Required for macOS
DOTS_SCRIPT="$DOTFILES_DIR/dots/src/dots.sh"
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"
DOTFILES_URL="$DOTFILES_URL" # Yes, we recursively set this here because of our loop sourcing
DOTFILES_GITHUB_USER="$(basename "$(dirname "$DOTFILES_URL")")" # Dynamically fill this based on the dotfiles URL

# TODO: Add a function that allows you to see what dotfiles were linked

# Checks that dotfiles are up to date each time a terminal starts
dots_get_dotfiles_status() {
	if [ -d "$DOTFILES_DIR" ] ; then
		dots_status
	else
		echo "Dotfiles directory does not exist."
	fi
}

# Ensures the shell being used is supported, warns if not
dots_check_shell() {
	if [ "$SHELL" != "/bin/zsh" ] && [ "$SHELL" != "/bin/bash" ] ; then
		echo "Dots doesn't support $SHELL."
	fi
}

# Anything that Dots needs upon initialization goes here
dots_init() {
    if [ "$SHELL" = "/bin/zsh" ] ; then
		SHELL_CONFIG_FILE="$HOME/.zshrc"
	elif [ "$SHELL" = "/bin/bash" ] ; then
		SHELL_CONFIG_FILE="$HOME/.bash_profile"
	fi
}

# Print Dotfiles message on each shell start (will be initialized from core shell file)
dots_init_message() {
	echo "#################### $SHELL ####################"
	dots_check_shell
	echo "Hostname: $HOSTNAME"
    echo "Dots $DOTS_VERSION"
	echo "Powered by $DOTFILES_GITHUB_USER's Dotfiles"
	echo ""
	echo "Dotfiles status: "
	dots_get_dotfiles_status
	echo "##################################################"
}

# Push Dotfiles up to the Git server
dots_push() {
	if [ -d "$DOTFILES_DIR" ] ; then
		git -C "$DOTFILES_DIR" add .
		git -C "$DOTFILES_DIR" commit -m "Updated dotfiles"
		git -C "$DOTFILES_DIR" push > /dev/null 2>&1 && echo "Dotfiles pushed!" || echo "Error pushing Dotfiles"
	else
		echo "Dotfiles directory does not exist."
	fi
}

# Pull updates from the Dotfiles project
dots_pull() {	
    echo "Installing dotfiles..."
    if [ -d "$DOTFILES_DIR" ] ; then
		echo "Dots will pull updated Dotfiles. Be aware that this will override current Dotfiles. Press any key to continue."
		read -r
        git -C "$DOTFILES_DIR" pull > /dev/null 2>&1 && echo "Dotfiles pulled!" || echo "Error pulling Dotfiles"
    else
		echo "Dotfiles directory does not exist."
    fi
}

# Resets the .zshrc/.bash_profile files to only contain Dots and the config
dots_reset_terminal_config() {
	rm "$SHELL_CONFIG_FILE"

	if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/bin/bash" ] ; then
		{
			echo "# Dots Config";
			echo "DOTFILES_URL=\"$DOTFILES_URL\"";
			echo ". $DOTS_SCRIPT";
			echo ". $DOTS_CONFIG_FILE";
            echo "dots_init"
            if [ "$SHOW_INIT_MESSAGE" ] ; then
			    echo "dots_init_message";
            fi
			echo "";
			echo "# Dotfiles Config";
		} >> "$SHELL_CONFIG_FILE"
	fi
}

# Installs the newly pulled dotfiles
dots_install() {
	if [ -f "$DOTS_CONFIG_FILE" ] ; then
		dots_reset_terminal_config

		# This command is sourced from "$DOTS_CONFIG_FILE":
		dots_config_up && echo "Dotfiles installed!" || echo "Error installing Dotfiles"
	else
		echo "Dots couldn't find $DOTS_CONFIG_FILE."
	fi
}

# Cleans dotfiles
dots_clean() {
	if [ -f "$DOTS_CONFIG_FILE" ] ; then
		dots_reset_terminal_config

		# This command is sourced from "$DOTS_CONFIG_FILE":
		dots_config_down && echo "Dotfiles cleaned!" || echo "Error cleaning Dotfiles"
	else
		echo "Dots couldn't find $DOTS_CONFIG_FILE."
	fi
}

# Gets the status of dotfiles
dots_status() {
    git -C "$DOTFILES_DIR" remote update > /dev/null 2>&1 || echo "Error updating from remote Dotfiles"
    git -C "$DOTFILES_DIR" status -s -b || echo "Couldn't check remote Dotfiles"
}

# Syncs dotfiles from your local machine to and from your dotfiles repo
dots_sync() {
    dots_push
	dots_pull
	dots_install
	dots_source
}

# Sources the shell
dots_source() {
	. "$SHELL_CONFIG_FILE"
}
