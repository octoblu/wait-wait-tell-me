#!/bin/bash

main(){
  local service="$1"
  local version="$2"

  local exit_code

  while true; do
    t1000 status "$service" --json | js '.minorVersion' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "deploying $service to minor"
    break
  done

  while true; do
    t1000 status "$service" --json | jq '.servers[] | select(.name | contains("minor")) | .version' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "deployed $service to minor"
    break
  done


  while true; do
    t1000 status "$service" --json | js '.majorVersion' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "deploying $service to major"
    break
  done

  while true; do
    t1000 status "$service" --json | jq '.servers[] | select(.name | contains("major")) | .version' | grep "$version"
    exit_code=$?

    if [ "$exit_code" != "0" ]; then
      sleep 0.5
      continue
    fi

    say "deployed $service to major"
    break
  done
}
main $@
