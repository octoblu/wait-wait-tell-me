#!/bin/bash

script_directory(){
  local source="${BASH_SOURCE[0]}"
  local dir=""

  while [ -h "$source" ]; do # resolve $source until the file is no longer a symlink
    dir="$( cd -P "$( dirname "$source" )" && pwd )"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source" # if $source was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done

  dir="$( cd -P "$( dirname "$source" )" && pwd )"

  echo "$dir"
}

usage(){
  echo 'USAGE: wait-wait-tell-me [options] <project-name> <version>'
  echo ''
  echo 'example: wait-wait-tell-me'
  echo ''
  echo '  -h, --help                 print this help text'
  echo '  -v, --version              print the version'
  echo ''
  echo ''
}

version(){
  local directory="$(script_directory)"
  local version=$(cat "$directory/VERSION")

  echo "$version"
}

main(){
  local service="$1"
  local version="$2"

  if [ "$service" == "-h" -o "$service" == "--help" ]; then
    usage
    exit 0
  fi

  if [ "$service" == "-v" -o "$service" == "--version" ]; then
    version
    exit 0
  fi

  local exit_code

  while true; do
    t1000 status "$service" --json | jq '.minorVersion' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "$service minor pulling"
    break
  done

  while true; do
    t1000 status "$service" --json | jq '.servers[] | select(.name | contains("minor")) | .version' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "$service minor deployed"
    break
  done


  while true; do
    t1000 status "$service" --json | jq '.majorVersion' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "$service major pulling"
    break
  done

  while true; do
    t1000 status "$service" --json | jq '.servers[] | select(.name | contains("major")) | .version' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "$service major deployed"
    break
  done

  say "deployment complete"
}
main $@
