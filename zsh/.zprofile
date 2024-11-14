# .zprofile [1] Used for executing user's commands at start, will be sourced
# when starting as a login shell.

# macOS is obnoxious and overwrites the PATH from a users ~/.zshenv, which is
# sourced first, in /etc/zprofile by calling `/usr/libexec/path_helper -s` so
# this is required so that PATH is once again set to the desired value.
[ `uname` = Darwin ] && source ~/.zshenv
