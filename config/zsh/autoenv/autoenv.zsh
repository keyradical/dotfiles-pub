# Automatically update the environment when the current working directory
# changes, this is a reimplementation of the ideas found in the repository
# https://github.com/Tarrasch/zsh-autoenv stripped down to bare essentials.
#
# The secret sauce can be found at the bottom of this file, where the chpwd
# hook function _autoenv_chpwd is added.

# The autoenv command provides a convenient way to create, edit, and remove
# enter and exit scripts in the current directory.
autoenv() {
  local cmd=$1
  case "$cmd" in
    -h|--help)  # Display help.
      echo "\
usage: autoenv [-h] {init,edit,deinit,reload,add=py}

options:
        -h, --help  show this help message and exit

commands:
        init        add .enter and .exit scripts in current directory
        edit        edit .enter and .exit scripts in current directory
        deinit      remove .enter and .exit scripts in current directory
        reload      reload the current environment
        add=local   add .local/bin to PATH
        add=py      add Python virtualenv to the autoenv"
      ;;

    init)  # Create .enter and .exit scripts in current directory.
      if [ -f $PWD/.enter ] || [ -f $PWD/.exit ]; then
        echo '.enter or .exit already exists'; return 1
      fi
      # Create the .enter and .exit scripts.
      touch .enter .exit
      # If enter script exists, authorize it.
      [ -f $PWD/.enter ] && _autoenv_authorized $PWD/.enter yes
      # If exit script exists, authorize it.
      [ -f $PWD/.exit ] && _autoenv_authorized $PWD/.exit yes
      # Enter the autoenv.
      _autoenv_enter $PWD
      ;;

    edit)  # Edit .enter and .exit scripts in current directory.
      if ! [ -f $PWD/.enter ] || ! [ -f $PWD/.exit ]; then
        echo '.enter or .exit not found'; return 1
      fi
      # Exit the autoenv before editing.
      _autoenv_exit $PWD
      if $EDITOR -p $PWD/.enter $PWD/.exit; then
        # If enter script exists, authorize it.
        [ -f $PWD/.enter ] && _autoenv_authorized $PWD/.enter yes
        # If exit script exists, authorize it.
        [ -f $PWD/.exit ] && _autoenv_authorized $PWD/.exit yes
      fi
      # Enter the autoenv.
      _autoenv_enter $PWD
      ;;

    deinit)  # Remove .enter and .exit scripts in current directory.
      if ! [ -f $PWD/.enter ] || ! [ -f $PWD/.exit ]; then
        echo '.enter or .exit not found'; return 1
      fi
      # Prompt user to confirm removal of enter and exit scripts.
      while true; do
        read "answer?Are you sure [y/N]? "
        case "$answer" in
          y|Y|yes)
            # Exit the autoenv.
            _autoenv_exit $PWD
            # Remove enter and exit scripts if they exist.
            [ -f $PWD/.enter ] && rm $PWD/.enter
            [ -f $PWD/.exit ] && rm $PWD/.exit
            break ;;
          *) break ;;
        esac
      done
      ;;

    reload)  # Reload the current environment
      if ! [ -f $PWD/.enter ] || ! [ -f $PWD/.exit ]; then
        echo '.enter or .exit not found'; return 1
      fi
      # Exit the autoenv before editing.
      _autoenv_exit $PWD
      # Enter the autoenv.
      _autoenv_enter $PWD
      ;;

    add=local)  # Add .local/bin to PATH
      if ! [ -f $PWD/.enter ] || ! [ -f $PWD/.exit ]; then
        echo '.enter or .exit not found'; return 1
      fi
      _autoenv_exit $PWD
      # Create .local/bin if not present
      if ! [ -d $PWD/.local/bin ]; then
        mkdir -p $PWD/.local/bin
      fi
      # On enter: store PATH and insert .local/bin
      echo 'OLDPATH=$PATH' >> .enter
      echo 'PATH=$PWD/.local/bin:$PATH' >> .enter
      # On exit: reset PATH
      echo 'PATH=$OLDPATH' >> .exit
      echo 'unset OLDPATH' >> .exit
      # Authorize modified autoenv
      _autoenv_authorized $PWD/.enter yes
      _autoenv_authorized $PWD/.exit yes
      _autoenv_enter $PWD
      ;;

    add=py)  # Add Python virtualenv to the sandbox
      if ! [ -f $PWD/.enter ] || ! [ -f $PWD/.exit ]; then
        echo '.enter or .exit not found'; return 1
      fi
      _autoenv_exit $PWD
      virtualenv -p `command -v python` .local
      echo 'source ${0:a:h}/.local/bin/activate' >> .enter
      echo 'deactivate' >> .exit
      _autoenv_authorized $PWD/.enter yes
      _autoenv_authorized $PWD/.exit yes
      _autoenv_enter $PWD
      pip install pynvim
      ;;

    *)  # Invalid arguments, show help then error.
      echo "invalid arguments: $@"
      autoenv --help
      return 1
      ;;
  esac
}

# Global entered directories array.
_autoenv_entered=()

# Load zstat from stat module for inspecting modified time.
zmodload -F zsh/stat b:zstat

# Check if the given file is authorized, if not prompt the user to authorize,
# ignore, or view the file. Authorized files and their modified times are
# stored in the $XDG_STATE_HOME/autoenv/authorized file to make authorization
# persistent.
_autoenv_authorized() {
  local file=$1 yes=$2
  # If autoenv state directory does not exist, create it.
  ! [ -d ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv ] && \
    mkdir -p ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv
  # Migrate from cache to state directory
  [ -f $HOME/.cache/autoenv/authorized ] && \
    mv $HOME/.cache/autoenv/authorized \
       ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv/authorized
  # If the authorized file does not exist, create it.
  ! [ -f ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv/authorized ] && \
    touch ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv/authorized
  # Load the authorized file into a map of authorized key value pairs.
  typeset -A authorized=(`cat ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv/authorized`)
  # If the file has been removed, return.
  ! [ -f $file ] && return 1
  # If the given file has been authorized, i.e. the modified time matches that
  # held in the authorized file, return.
  local modified_time=`zstat +mtime $file`
  [ "$authorized[$file]" = "$modified_time" ] && return
  # If yes, don't prompt for user confirmation.
  if [ "$yes" != "yes" ]; then
    # Prompt to authorize file.
    while true; do
      read "answer?Authorize $file [Y/n/v]? "
      case "$answer" in
        y|Y|yes|'') break ;;    # Authorize the file.
        n|N|no) return 1 ;;     # Do not authorize the file.
        v|V|view) cat $file ;;  # View the file.
      esac
    done
  fi
  # Add file to the authorized map.
  authorized[$file]=$modified_time
  # Store authorized map in authorized file.
  echo ${(kv)authorized} > ${XDG_STATE_HOME:-$HOME/.local/state}/autoenv/authorized
}

# Source an enter script and add its directory to the global entered
# directories array.
_autoenv_enter() {
  local entered=$1
  # If entered exists in the entered directories array, return.
  (( ${+_autoenv_entered[${_autoenv_entered[(i)$entered]}]} )) && return
  # If the enter script is not authorized, return.
  _autoenv_authorized $entered/.enter || return
  # Source the enter script.
  source $entered/.enter
  # Add the entered directory to the global entered array.
  _autoenv_entered+=$entered
}

# Source an exit script and remove its directory from the global entered
# directories array.
_autoenv_exit() {
  local entered=$1
  # If the exit script is not authorized, return.
  _autoenv_authorized $entered/.exit || return
  # Source the exit script.
  source $entered/.exit
  # Remove the entered directory from the global entered array.
  _autoenv_entered[${_autoenv_entered[(i)$entered]}]=()
}

# Find all directories containing a .enter file by searching up the directory
# tree starting in the current directory.
_autoenv_find_enter_directories() {
  local current=$PWD
  # If an enter script is found in the current directory, return it.
  [ -f $current/.enter ] && echo $current
  # Loop until an enter script or the root directory is found.
  while true; do
    # Go up one directory and make the path absolute.
    local next=$current/..; local next=${next:A}
    # If an enter script is found in the current directory, return it.
    [ -f $next/.enter ] && echo $next
    # If the current directory equals the next directory we are done, otherwise
    # update the current directory.
    [[ $current == $next ]] && return || local current=$next
  done
}

# A chpwd hook function which automatically sources enter and exit scripts to
# setup local environments for directory and its subdirectories.
_autoenv_chpwd() {
  local entered
  # Loop over the reversed entered directory array.
  for entered in ${(aO)_autoenv_entered}; do
    # If the the current directory was previously entered then exit.
    ! [[ $PWD/ == $entered/* ]] && _autoenv_exit $entered
  done
  # Find all enter script directories, store them in an array.
  local enter_dirs=(`_autoenv_find_enter_directories`)
  # Loop over reversed enter script directories array, so enter scripts found
  # last are sourced first, then source all enter scripts.
  for enter in ${(aO)enter_dirs}; do _autoenv_enter $enter; done
}

# Register the autoenv chpwd hook.
autoload -U add-zsh-hook
add-zsh-hook chpwd _autoenv_chpwd

# Ensure autoenv is activated in the current directory on first load.
_autoenv_chpwd
