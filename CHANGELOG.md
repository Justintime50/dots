# CHANGELOG

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
