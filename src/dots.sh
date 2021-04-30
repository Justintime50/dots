# shellcheck disable=SC1090,SC2148,SC2269

HOSTNAME=$(hostname) # Required for macOS
DOTFILES_DIR="$HOME/.dotfiles"
DOTS_SCRIPT="$DOTFILES_DIR/dots/src/dots.sh"
DOTS_CONFIG_FILE="$DOTFILES_DIR/dots-config.sh"
DOTFILES_URL="$DOTFILES_URL"
DOTFILES_GITHUB_USER="$(basename "$(dirname "$DOTFILES_URL")")" # Dynamically fill this based on the dotfiles URL

# TODO: Add a function that allows you to see what dotfiles were linked

# Checks that dotfiles are up to date each time a terminal starts
dots_get_dotfiles_status() {
	if [[ -d "$DOTFILES_DIR" ]] ; then
		git -C "$DOTFILES_DIR" remote update > /dev/null 2>&1 || echo "Error updating from remote Dotfiles"
		git -C "$DOTFILES_DIR" status -s -b || echo "Couldn't check remote Dotfiles"
	else
		echo "Dotfiles directory does not exist."
	fi
}

# Ensures the shell being used is supported, warns if not
dots_check_shell() {
	if [[ "$SHELL" != "/bin/zsh" && "$SHELL" != "/bin/bash" ]] ; then
		echo "Dots doesn't support $SHELL."
	fi
}

# Print Dotfiles message on each shell start (will be initialized from core shell file)
dots_init_message() {
	echo "#################### $SHELL ####################"
	dots_check_shell
	echo "Hostname: $HOSTNAME"
	echo "Powered by $DOTFILES_GITHUB_USER's Dotfiles"
	echo ""
	echo "Dotfiles status: "
	dots_get_dotfiles_status
	echo "##################################################"
}

# Push Dotfiles up to the Git server
dots_push() {
	if [[ -d "$DOTFILES_DIR" ]] ; then
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
    if [[ -d "$DOTFILES_DIR" ]] ; then
		echo "Dots will pull updated Dotfiles. Be aware that this will override current Dotfiles. Press any key to continue."
		read -rn 1
        git -C "$DOTFILES_DIR" pull > /dev/null 2>&1 && echo "Dotfiles pulled!" || echo "Error pulling Dotfiles"
    else
		echo "Dotfiles directory does not exist."
    fi
}

# Resets the .zshrc/.bash_profile files to only contain Dots and the config
dots_reset_terminal_config() {
	local shell_config_file
	
	if [[ "$SHELL" == "/bin/zsh" ]] ; then
		shell_config_file="$HOME/.zshrc"
		rm "$shell_config_file"
	elif [[ "$SHELL" == "/bin/bash" ]] ; then
		shell_config_file="$HOME/.bash_profile"
		rm "$shell_config_file"
	fi

	if [[ "$SHELL" == "/bin/zsh" || "$SHELL" == "/bin/bash" ]] ; then
		{
			echo "# Dots Config";
			echo "DOTFILES_URL=\"$DOTFILES_URL\"";
			echo ". $DOTS_SCRIPT";
			echo ". $DOTS_CONFIG_FILE";
			echo "dots_init_message";
			echo "";
			echo "# Dotfiles Config";
		} >> "$shell_config_file"
	fi
}

# Installs the newly pulled dotfiles
dots_install() {
	if [[ -f "$DOTS_CONFIG_FILE" ]] ; then
		dots_reset_terminal_config

		# This command is sourced from "$DOTS_CONFIG_FILE":
		dots_config_up && echo "Dotfiles installed!" || echo "Error installing Dotfiles"
	else
		echo "Dots couldn't find $DOTS_CONFIG_FILE."
	fi
}

# Cleans dotfiles
dots_clean() {
	if [[ -f "$DOTS_CONFIG_FILE" ]] ; then
		dots_reset_terminal_config

		# This command is sourced from "$DOTS_CONFIG_FILE":
		dots_config_down && echo "Dotfiles cleaned!" || echo "Error cleaning Dotfiles"
	else
		echo "Dots couldn't find $DOTS_CONFIG_FILE."
	fi
}

dots_sync() {
	# TODO: Do we want to push as a first step?
	# 1. Pull new dotfiles
	# 2. Install the dotfiles based on user config
	# 3. Source the new Dotfiles
	dots_pull
	dots_install
	dots_source
}

# Sources the shell
dots_source() {
	exec "$SHELL"
}
