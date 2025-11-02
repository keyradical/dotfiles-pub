if [[ "" == $SANDBOX_ROOT ]]; then
  export SANDBOX_ROOT=$HOME/Sandbox
fi

sandbox() {
  local usage="\
usage: sandbox [-h] {create,rename,destroy,enable,disable,list} ..
       sandbox create [--git <repo>] <name>
       sandbox rename <old-name> <new-name>
       sandbox destroy <name>
       sandbox enable <name>
       sandbox disable
       sandbox list"

  error() { print -P "%F{red}error:%f $1" }

  local cmd=$1
  [[ -z "$cmd" ]] && \
    error "missing command\n$usage" && return 1
  shift 1

  case $cmd in
    create)
      # Parse command arguments.
      local git=false
      for arg in $@; do
        if [ "${arg[1]}" = - ]; then
          if [ "$git" = true ]; then
            error "invalid --git <repo> $arg\n$usage" && return 1
          elif [ "$arg" = --git ]; then
            git=true
          else
            error "invalid option $arg\n$usage" && return 1
          fi
        else
          if [ "$git" = true ]; then
            local repo=$arg
            git=false
          elif [[ -z "$name" ]]; then
            error "invalid argument $arg\n$usage" && return 1
          else
            local name=$arg
          fi
        fi
      done
      unset git
      [[ -z "$name" ]] && \
        error "missing argument <name>\n$usage" && return 1
      local sandbox=$SANDBOX_ROOT/$name
      [[ -d "$sandbox" ]] && \
        error "sandbox already exists $name" && return 1
      if [[ -n "$repo" ]]; then
        mkdir -p $SANDBOX_ROOT &> /dev/null
        git clone $repo $sandbox
        cd $sandbox
      else
        mkdir -p $sandbox &> /dev/null
        cd $sandbox
        git init &> /dev/null
      fi
      echo "SANDBOX_HOME=\$(dirname -- "\$0:a")" >> $sandbox/.enter
      echo "SANDBOX_NAME=$name" >> $sandbox/.enter
      _autoenv_authorized $sandbox/.enter yes
      echo "unset SANDBOX_NAME" >> $sandbox/.exit
      echo "unset SANDBOX_HOME" >> $sandbox/.exit
      _autoenv_authorized $sandbox/.exit yes
      _autoenv_enter $sandbox
      ;;

    rename)
      local old_name=$1 new_name=$2
      [[ -z "$old_name" ]] && \
        error "missing argument <old-name>\n$usage" && return 1
      [[ -z "$new_name" ]] && \
        error "missing argument <new-name>\n$usage" && return 1
      local old=$SANDBOX_ROOT/$old_name new=$SANDBOX_ROOT/$new_name
      [[ ! -d "$old" ]] && \
        error "sandbox does not exist $old_name" && return 1
      [[ -d "$new" ]] && \
        error "sandbox already exists $new_name" && return 1
      [[ "$PWD" = "$old"* ]] && _autoenv_exit $PWD
      mv $old $new
      sed -i "s/$old_name/$new_name/g" $new/.enter
      _autoenv_authorized $new/.enter yes
      _autoenv_authorized $new/.exit yes
      [[ "$PWD" = "$old"* ]] && cd $new
      ;;

    destroy)
      local name=$1
      [[ -z "$name" ]] && \
        error "missing argument <name>\n$usage" && return 1
      local sandbox=$SANDBOX_ROOT/$name
      [[ ! -d $sandbox ]] && \
        error "sandbox does not exist $name" && return 1
      [[ "$PWD" = "$sandbox"* ]] && cd ~
      rm -rf $sandbox
      ;;

    list)
      ls -1 $SANDBOX_ROOT | less -F -K -R -X
      ;;

    enable)
      local name=$1
      [[ -z "$name" ]] && \
        error "missing argument <name>\n$usage" && return 1

      local sandbox=$SANDBOX_ROOT/$name
      [[ ! -d $sandbox ]] && \
        error "sandbox does not exist $name" && return 1
      export SANDBOX_RETURN=$PWD
      cd $sandbox
      ;;

    disable)
      [[ -z "$SANDBOX_RETURN" ]] && \
        error "sandbox is not currently active" && return 1
      cd $SANDBOX_RETURN
      unset SANDBOX_RETURN
      ;;

    *)
      error "invalid sandbox command: $cmd" && return 1
      ;;
  esac
}
