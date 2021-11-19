# CHANGELOG

## v0.9.0 (2021-11-19)

* Adds support for `sh`, `dash`, and `ksh` shells by using the `~/.profile` (closes #5)
* Added a missing check to ensure that the shell config file exists for functions that need it

## v0.8.0 (2021-10-07)

* Adds a `dots_list` function which shows the dotfiles that were last installed (closes #4)
* Adds logging for the `install` and `clean` steps for debugging and for the usage of `dots_list` (these can be found at `~/.dots`)
* Adds a prompt on the `dots_clean` step to ensure the user wants to proceed

## v0.7.0 (2021-09-06)

* Code refactor cutting out redundant validation checks, making error handling modular, and properly exiting Dots when an error occurs
* We now properly initialize Dots when running the standalone `dots_source` function
* Cleaned up `dots` namespace by prepending internal helper functions with an underscore (those functions that aren't intended to be used by users. This should assist with autocorrect)

## v0.6.1 (2021-09-02)

* Separates `dots_check_shell` from `dots_init_message`
* Adds `dots_check_shell` to `dots_init` and properly exits of the shell is not supported
* Overwrites the contents of `$SHELL_CONFIG_FILE` instead of removing and appending to it in `dots_reset_terminal_config` (closes #2)

## v0.6.0 (2021-09-01)

* Swaps the order in `dots_sync` to `pull` first and `push` second instead of the previous order which was reversed
* Rebasing is now the `git pull` strategy for Dots
* Swaps the location of the `shell` and `dots version` in the shell initialization message

## v0.5.2 (2021-07-22)

* Fixes odd indentation errors

## v0.5.1 (2021-07-22)

* Shuffled messages around and added more for better feedback to the user

## v0.5.0 (2021-07-22)

* Made showing the Dots message on shell start optional (default: true)
* `dots_sync` now attempts to push before pulling, if you cannot reliably sync dotfiles due to conflicts, you can run the intermediate manual steps (push/pull, etc) first
* Added the Dots version number to the init message
* Clarified documentation

## v0.4.1 (2021-06-19)

* Shifted remote status update to new `dots_status` function as it was unintentionally left behind

## v0.4.0 (2021-06-09)

* Adds `dots_status` function to get the status of the dotfiles

## v0.3.0 (2021-05-03)

* Lints project and makes it compatible with all shells (sh, bash, dash, ksh)
* Replaces `exec $SHELL` with `. $SHELL_CONFIG_FILE` (closes #1)

## v0.2.0 (2021-04-30)

* Added installation script to assist with getting started with Dots
* Changed `dots_bounce` to `dots_source` to source the shell
* Removes the cloning functionality as it will never be used
* Various code refactors
* Updated documentation surrounding installation

## v0.1.0 (2021-04-30)

* Initial release
* Push/pull/install/clean Dotfiles
* Complete documentation on configuration and usage
