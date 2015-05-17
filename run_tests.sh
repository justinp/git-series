#!/bin/bash

DIR=$( cd $(dirname "$0") && pwd )
export PATH="$PATH:$DIR"

function usage {
  cat >&2 <<EOS
usage: run_tests.sh [options]

Options:
  -h  show usage
  -k  keep temporary git repositories
  -v  verbose mode
EOS
  exit 1
}

while getopts ":hkv" opt; do
  case $opt in
    k)
      export KEEP_REPOS=y
      ;;
    v)
      export VERBOSE=y
      ;;
    *)
      usage
      ;;
  esac
done
shift $((OPTIND - 1))

if [ -n "$1" ]; then
  usage
fi

cd "$DIR"/tests
for f in *.sh; do
  if [ -x $f ]; then
    ./$f
    rc=$?
    if [ $rc != 0 ]; then
      exit $rc
    fi
  fi
done

