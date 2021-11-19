<div align="center">

# Dots

The simple, flexible, Dotfile manager.

[![Build Status](https://github.com/Justintime50/dots/workflows/build/badge.svg)](https://github.com/Justintime50/dots/actions)
[![Version](https://img.shields.io/github/v/tag/Justintime50/dots)](https://github.com/Justintime50/dots/releases)
[![Licence](https://img.shields.io/github/license/justintime50/dots)](LICENSE)

<img src="https://raw.githubusercontent.com/justintime50/assets/main/src/dots/showcase.png" alt="Showcase">

</div>

Dots is a simple Dotfile manager that is incredibly flexible. Your workflow is different from everyone else, why conform to an opinionated set of dotfile logic?

Dots was created because projects such as [Dotbot](https://github.com/anishathalye/dotbot) only install/link your dotfiles but don't help you sync them across computers and projects while [Dotman](https://github.com/Bhupesh-V/dotman) only helps you sync your dotfiles but not actually install/link them. I needed a system that could do both.

Dots makes no assumptions as to how or where your dotfiles should be installed. Dots allows you to specify "Dotfiles as code", allowing you to craft any configuration of dotfiles that fits your needs. Simply provide a list of commands to run such as symlinking or moving your dotfiles around and Dots will take care of the rest.

**Notable Features**

* Warns you when your Dotfiles are out of sync
* Push, pull, install, and clean your Dotfiles
* Setup your Dotfiles based on your own custom configuration
* Support for `zsh`, `bash`, `sh`, `dash`, and `ksh`
* Optionally prints info about your Dots on each shell start:

```
################### Dots v1.0.0 ###################
Shell: /bin/zsh
Hostname: MacBook-Pro-Justin

Dotfiles status:
## main...origin/main [behind 1]
###################################################
```

## Install

Dots will override your current Dotfiles, namely `~/.zshrc` for `zsh`, `~/.bash_profile` for `bash` and `~/.profile` for `sh`, `dash`, and `ksh` shells. Dots will create a blank shell config file and source your remaining files into it. See [Configuration](#Configuration) below for more details.

To install Dots, simply drop it into your current Dotfiles project:

* If installing Dots into your current Dotfiles project, follow step `1a`.
* If installing your Dotfiles on a new machine (assumes Dots is already in your Dotfiles project), follow step `1b`.
* Regardless of which part of step 1 you follow, run steps 2.

```bash
# 1a) Add Dots as a git submodule in your Dotfiles project
git submodule add https://github.com/Justintime50/dots.git

# 1b) Clone your Dotfiles and initialize the Dots submodule (replace USERNAME)
git clone https://github.com/USERNAME/dotfiles.git "$HOME/.dotfiles"
git -C "$HOME/.dotfiles" submodule init && git -C "$HOME/.dotfiles" submodule update

# 2) Install Dots
# Installation assumes your dotfiles are are stored at `~/.dotfiles`; if not, alter the `DOTFILES_DIR` variable in `install.sh`
$HOME/.dotfiles/dots/src/install.sh
```

## Usage

Using Dots is simple. Make changes to your Dotfiles, then run any of the following commands.

```bash
# Push Dotfile changes
dots_push

# Pull new Dotfile changes
dots_pull

# Install Dotfiles (uses `up` function in dots-config.sh)
dots_install

# Source all new Dotfiles
dots_source

# Pull/push/install/source Dotfile changes
dots_sync

# Clean Dotfiles (uses `down` function in dots-config.sh)
dots_clean

# Get the status of the dotfiles
dots_status

# Show the list of dotfiles installed
dots_list

# To update Dots once it's a submodule in your Dotfiles project, run the following
git submodule update --remote dots
```

**Dots Shell Initialization Message**

If you would like to not show the Dots message on shell start, simply make the `DOTS_SHOW_DOTS_MESSAGE` variable found in `dots.sh` empty.

## Configuration

The only thing Dots requires for configuration is a file in the root of your Dotfiles project titled `dots-config.sh` with two functions. Much like a database migration file, we provide a list of instructions (up and down) to install or clean our Dotfiles. A simple example is shown below:

### Basic Configuration

```bash
# The variable "DOTFILES_DIR" is available to use here (points to $HOME/.dotfiles)

# Instructions run when installing/updating Dotfiles
dots_config_up() {
    ln -sfn "$DOTFILES_DIR"/src/personal/home/.gitconfig "$HOME"/.gitconfig
}

# Instructions run when cleaning Dotfiles
dots_config_down() {
    rm -i "$HOME"/.gitconfig
}
```

### Advanced Configuration

```bash
# The variable "DOTFILES_DIR" is available to use here (points to $HOME/.dotfiles)

# Instructions run when installing/updating Dotfiles
dots_config_up() {
    # Specifying a hostname is completely optional, but an effective way to ensure
    # computer-specific Dotfiles are installed properly. One config file can configure
    # multiple computers depending on their HOSTNAME
    if [[ "$HOSTNAME" == "MacBook-Pro-Justin" ]] ; then
        ln -sfn "$DOTFILES_DIR"/src/personal/home/.gitconfig "$HOME"/.gitconfig
        echo ". $DOTFILES_DIR/src/personal/home/.zshrc" >> "$HOME"/.zshrc
        # Your list can be as long as you'd like
    fi

    if [[ "$HOSTNAME" == "Work-Computer" ]] ; then
        ln -sfn "$DOTFILES_DIR"/src/work/home/.gitconfig "$HOME"/.gitconfig
        echo ". $DOTFILES_DIR/src/work/home/.zshrc" >> "$HOME"/.zshrc
        # Your list can be as long as you'd like
    fi
}

# Instructions run when cleaning Dotfiles
dots_config_down() {
    if [[ "$HOSTNAME" == "MacBook-Pro-Justin" ]] ; then
        rm -i "$HOME"/.gitconfig
        # .zshrc taken care of by Dots
    fi

    if [[ "$HOSTNAME" == "Work-Computer" ]] ; then
        rm -i "$HOME"/.gitconfig
        # .zshrc taken care of by Dots
    fi
}
```
