#!/bin/sh

# This script builds/rebuilds containers
#
#

BUILD_OPTS=

usage() {
  echo "Usage: $0 [--no-cache --no-push --rm] [-p registry prefix path ] container container ..."
  echo "\t --no-cache - Do not use cache when building the image"
  echo "\t --no-push  - Do not publish into remote repository"
  echo "\t --rm       - Remove intermediate containers after a successful build" 
  echo
  echo "\t -p         - Path to remote registry including prefix, ex: quay.io/myusername/" 
}

TEMP=`getopt -o p: -l no-cache,no-push,rm -- "$@"`
parse_status=$?

# parse check
[ "0" != $parse_status ] && { echo && usage && exit $parse_status; }

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -p)
      PREFIX_PATH=$2; shift 2;;
    --no-cache)
      BUILD_OPTS="${BUILD_OPTS} --no-cache"; shift;;
    --no-push)
      NO_PUSH=1; shift;;
    --rm)
      BUILD_OPTS="${BUILD_OPTS} --rm"; shift;;
    *) break;;
  esac
done

# check containers list
CONTAINERS=$@
[ $(echo ${CONTAINERS} | wc -w) = 0 ] && { usage && exit 1; }

# Execute build
for c in $CONTAINERS; do
  c=$(echo $c | sed -r 's/\/+$//')
  docker build ${BUILD_OPTS} -t ${PREFIX_PATH}${c} ${c} || continue

  # push is required
  [ "$NO_PUSH" != 1 ] && docker push ${PREFIX_PATH}${c}
done
