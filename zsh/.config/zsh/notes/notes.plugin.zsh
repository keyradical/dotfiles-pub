# TODO: Support opening multiple notes in buffers or tabs
note() {
  if [[ "$1" == "" ]]; then
    echo "usage: note \"<title>\""
  else
    vim -c "Note $1"
  fi
}
