# A collection of commands to make it easier to build projects.

# Default `build` alias to select a `build-dir` then invoke a build, using an
# alias means the configured build command's completion works out of the box.
alias build="build-dir --build"

# Detect installed debugger and set the `debug` alias to debug a program with
# command line arguments.
if [ `uname` = Linux ]; then
  autoload -U regexp-replace
  function vimdebug() {
    # For each item in $* replace * and \* and then replace \ with \\
    local args=()
    for arg in "$@"; do
      regexp-replace arg '\*' '\\*'
      args+=($arg)
    done
    nvim "+packadd termdebug" "+TermdebugCommand $args"
  }
  if command -v nvim &> /dev/null; then
    alias debug=vimdebug
  elif command -v gdb &> /dev/null; then
    alias debug='gdb --args'
  fi
elif [ `uname` = Darwin ]; then
  command -v lldb &> /dev/null && \
    alias debug='lldb --'
fi

# Interactively choose a `~build` directory for `build` to build.
build-dir() {
  local usage='usage: build-dir [-h] [-s] [--build] [<directory>]'
  local -a help show do_build
  zparseopts -D h=help -help=help s=show -show=show -build=do_build
  if [[ -n $help ]]; then
    cat << EOF
$usage

Find and select the current build directory interactively.

positional arguments:
  <directory> the build directory to select

optional arguments:
  -h, --help  show this help message and exit
  -s, --show  show the current build directory
  --build     invoke a build after selection
EOF
    return
  fi
  error() { echo "\e[31merror:\e[0m $1" }
  warning() { echo "\e[33mwarning:\e[0m $1" }
  if [[ -n $show ]]; then
    if [[ ! -n $build_dir ]]; then
      error "build directory not set"
      return 1
    else
      echo "$build_dir"
      return
    fi
  fi
  local local_build_dir
  if [[ ${#*} -gt 1 ]]; then
    echo $usage
    error "unexpected positional arguments: ${*[2,${#*}]}"; return 1
  elif [[ ${#*} -eq 1 ]]; then
    if [[ ! -d ${*[1]} ]]; then
      warning "directory not found: ${*[1]}"
    else
      local_build_dir=${*[1]}
    fi
  fi

  # If <directory> was not set begin selection
  if [[ -z $local_build_dir ]]; then
    # Find build directories
    local -a local_build_dirs
    for entry in `ls -A`; do
      [ -d $entry ] && [[ $entry =~ build* ]] && \
        local_build_dirs+=${entry/\//}
    done

    # Interactively select a build directory if more than 1 found
    integer index=0
    if [[ ${#local_build_dirs} -eq 0 ]]; then
      error "no build directories found"; return 1
    elif [[ ${#local_build_dirs} -eq 1 ]]; then
      local_build_dir=${local_build_dirs[1]}
    elif [[ ${#local_build_dirs} -gt 1 ]]; then
      # Use fzf to select a build directory
      local max=$(( $( tput lines ) / 2 ))
      local best=$(( ${#local_build_dirs} + 4 ))
      local_build_dir=$(
        printf '%s\n' "${local_build_dirs[@]}" |
        fzf --layout=reverse --tac --info=hidden --border=rounded \
            --cycle --height=$(( $best < $max ? $best : $max ))
      )
      if [[ $? -ne 0 ]]; then
        return 1
      fi
    fi
  fi

  # If `build.ninja` exists in alias `ninja`, return.
  local build
  [ -f $local_build_dir/build.ninja ] && \
    build="ninja -C $local_build_dir"

  # If `Makefile` exists in alias `make`, return.
  if [ -f $local_build_dir/Makefile ]; then
    [ `uname` = Darwin ] && \
      local cpu_count=`sysctl -n hw.ncpu` ||
      local cpu_count=`grep -c '^processor' /proc/cpuinfo`
    build="make -j $cpu_count -C $local_build_dir"
  fi

  # If the build variable is not defined the command could not be determined
  if [ -z $build ]; then
    warning "build command detection failed: $local_build_dir"
    # Prompt user to enter a build command
    vared -p 'enter comand: ' build
  fi

  # Redefine the `build` alias and update the `~build` hash directory
  alias build="$build"
  hash -d build=$local_build_dir
  export build_dir=$local_build_dir
  export BUILD_DIR=$PWD/$local_build_dir

  # If `--build` is specified then evaluate the command.
  if [[ -n $do_build ]]; then
    eval build
  fi

  # Bind C-B to fuzzy find & complete cmake variables.
  zle -N .build-var
  bindkey '^B' .build-var
}

# Build then run a target residing in `~build/bin`.
build-run() {
  local target=$1; shift 1
  eval build $target && ~build/bin/$target "$@"
}

# Build then debug a target residing in `~build/bin`.
build-debug() {
  local target=$1; shift 1
  eval build $target && debug ~build/bin/$target "$@"
}

# Fuzzy find CMake variables, select one to set the variable via a command.
.build-var() {
  local var=$(
    cat $build_dir/CMakeCache.txt |
    grep --color=never -Ex '^\w+:\w+=.*$' |
    fzf --layout=reverse --info=hidden --border=rounded \
        --cycle --height=50%
  )
  if [[ -n "$var" ]]; then
    if [[ "$BUFFER" = "cmake"* ]]; then
      BUFFER="$BUFFER-D$var"
    else
      BUFFER="cmake -B\$build_dir -D$var"
    fi
    zle end-of-line
  fi
  zle reset-prompt
}
