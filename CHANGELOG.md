# CHANGELOG

## v1.3.1 (2025-01-10)

- Makes various changes to how dotfiles are sourced providing a vastly improved experience, ensuring that dotfiles are fetched on every shell but without requiring the user to wait for that lengthy process
  - Use `git fetch` instead of `git remote update` to cut down on checked branches
  - Only recurse through submodules if changed, on-demand
  - Removed the temp dots timestamp file and concept added in v1.2.1 which was prone to failure due to VS Code ([closes #9](https://github.com/Justintime50/dots/issues/9))
  - Run `git fetch` in a suppressed subshell, allowing for shells to startup fast without waiting for that process to finalize. This ensures that every subsequent shell will show the dotfiles status if it differs

## v1.3.0 (2025-01-03)

- Adds `dots_diff` as a command to see what dotfiles have changed

## v1.2.1 (2024-12-30)

- Dotfile checking was previously too aggressive on every shell invocation which lead to slow shell starts. Dots will now only check the dotfiles status on first boot and once every 72 hours after that if machine stays on

## v1.2.0 (2024-10-23)

- Adds `DOTS_DISABLE_DOTFILES_STATUS` allowing bypass of the git status check on shell startup while maintaining the init message of Dots

## v1.1.2 (2022-02-10)

- Fixes a bug that inversed the check for `DOTS_DISABLE_INIT_MESSAGE` from the previous release

## v1.1.1 (2022-02-07)

- Fixes a bug that didn't properly check if `DOTS_DISABLE_INIT_MESSAGE` was set or not

## v1.1.0 (2022-02-06)

- Renames the `DOTS_SHOW_INIT_MESSAGE` to `DOTS_DISABLE_INIT_MESSAGE` to more accurately represent what's happening since the init message is always on by default
- Clarifies instructions to setup a custom dotfiles directory during installation
- Various small tweaks internally

## v1.0.0 (2021-11-21)

- Refactored variables for easier installation (now requiring no parameters to the install script), better reuse of code, and correctly namespaced items
  - `SHOW_DOTS_MESSAGE` is now `DOTS_SHOW_INIT_MESSAGE`
  - `DOTFILES_URL` is no longer used anywhere and no longer needed (this also means the "Powered by ... Dotfiles" message is gone)
- Added `dots_update` which will update Dots in your dotfiles project
- Fixed a bug that would throw an error if no shell config file was found on startup (this was problematic as we started assuming the user already had a shell config file; however, that may not be the case for a brand new machine getting setup with Dots)
- Various other improvements made to the underlyinng code including refactor, comments, updated documentation, etc

## v0.9.0 (2021-11-19)

- Adds support for `sh`, `dash`, and `ksh` shells by using the `~/.profile` (closes #5)
- Added a missing check to ensure that the shell config file exists for functions that need it

## v0.8.0 (2021-10-07)

- Adds a `dots_list` function which shows the dotfiles that were last installed (closes #4)
- Adds logging for the `install` and `clean` steps for debugging and for the usage of `dots_list` (these can be found at `~/.dots`)
- Adds a prompt on the `dots_clean` step to ensure the user wants to proceed

## v0.7.0 (2021-09-06)

- Code refactor cutting out redundant validation checks, making error handling modular, and properly exiting Dots when an error occurs
- We now properly initialize Dots when running the standalone `dots_source` function
- Cleaned up `dots` namespace by prepending internal helper functions with an underscore (those functions that aren't intended to be used by users. This should assist with autocorrect)

## v0.6.1 (2021-09-02)

- Separates `dots_check_shell` from `dots_init_message`
- Adds `dots_check_shell` to `dots_init` and properly exits of the shell is not supported
- Overwrites the contents of `$SHELL_CONFIG_FILE` instead of removing and appending to it in `dots_reset_terminal_config` (closes #2)

## v0.6.0 (2021-09-01)

- Swaps the order in `dots_sync` to `pull` first and `push` second instead of the previous order which was reversed
- Rebasing is now the `git pull` strategy for Dots
- Swaps the location of the `shell` and `dots version` in the shell initialization message

## v0.5.2 (2021-07-22)

- Fixes odd indentation errors

## v0.5.1 (2021-07-22)

- Shuffled messages around and added more for better feedback to the user

## v0.5.0 (2021-07-22)

- Made showing the Dots message on shell start optional (default: true)
- `dots_sync` now attempts to push before pulling, if you cannot reliably sync dotfiles due to conflicts, you can run the intermediate manual steps (push/pull, etc) first
- Added the Dots version number to the init message
- Clarified documentation

## v0.4.1 (2021-06-19)

- Shifted remote status update to new `dots_status` function as it was unintentionally left behind

## v0.4.0 (2021-06-09)

- Adds `dots_status` function to get the status of the dotfiles

## v0.3.0 (2021-05-03)

- Lints project and makes it compatible with all shells (sh, bash, dash, ksh)
- Replaces `exec $SHELL` with `. $SHELL_CONFIG_FILE` (closes #1)

## v0.2.0 (2021-04-30)

- Added installation script to assist with getting started with Dots
- Changed `dots_bounce` to `dots_source` to source the shell
- Removes the cloning functionality as it will never be used
- Various code refactors
- Updated documentation surrounding installation

## v0.1.0 (2021-04-30)

- Initial release
- Push/pull/install/clean Dotfiles
- Complete documentation on configuration and usage
