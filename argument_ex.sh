#!/usr/bin/env bash

# e - script stops on error (return != 0)
# o pipefail - script fails if one of piped command fails
set -eo pipefail

function usage()
{
    echo "Usage :  $0 [options] [--]
    Options:
    -h|help           Display this message
    -f|file [FILE]    File to do stuff with"
}

if [ $# -eq 0 ]; then
  usage; exit -1
fi

while [[ "$1" ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --file|-f)
      shift
      
      if [[ -z $1 ]]; then
        echo "ERROR: no file specified"; exit -1 
      fi

      FILE=$1 ;; 
    *) echo "ERROR: unknown switch $1"; usage; exit -1 ;;
  esac
  shift 
done

if [[ ! -z $FILE ]]; then
  echo $FILE
fi
