#!/bin/env bash

function usage()
{
  echo "Usage : $0 [options] [--]
  Options:
  -h|help         Display this message
  -p|pod POD      POD to pull logs for
  -t|tail COUNT   COUNT of messages to tail from log"
}

klo()
{
  if [ $# -eq 0 ]; then
    usage; exit -1
  fi

  while [[ "$1" ]]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --pod|-p) 
        shift

        if [[ -z $1 ]]; then
          echo "ERROR: no pod specified"; exit -1
        fi

        POD=$1 ;;
      --tail|-t)
        shift

        if [[ -z $1 ]]; then
          echo "ERROR: no count specified to tail"; exit -1
        fi

        TAIL=$1 ;;
      *) echo "ERROR: unknown switch $1"; usage; exit -1 ;;
    esac
    shift
  done
   
  k8_options=("-f")

  if [[ ! -z $TAIL ]]; then
    k8_options+=" --tail=$TAIL"
  fi

  if [[ ! -z $POD ]]; then
    local host=$(kubectl get pods | awk -v pod=$POD '$1 ~ pod {print $1}') 
    local count=$(kubectl get pods | awk -v pod=$POD '$1 ~ pod {print $1}' | wc -l) 
   
    # if awk returns more than one pod ask the user to choose 
    if [[ $count -ne 1 ]]; then
      echo "You must choose, but choose wisely:"
      select h in $host; do 
        if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $count]; then
          k8_options+=" $h"
          break;
        else
          echo "You have chosen poorly: Select any number from 1-$count"
        fi 
      done
    else
      k8_options+=" $host"
    fi

    k8_options+=" $host"
  fi

  kubectl logs ${k8_options[@]} blah-simple-webapp
}

klo "$@"
