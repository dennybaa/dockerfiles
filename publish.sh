#!/bin/sh

# This script builds/rebuilds containers and pushes them to remote registries.
# Examples:
#
# ./publish.sh -p quay.io/dennybaa/ droneunit-ubuntu                    => quay.io/dennybaa/droneunit-ubuntu
# ./publish.sh --no-push -p quay.io/dennybaa/ $(ls -d */)               => builds all containers
# ./publish.sh -p quay.io/dennybaa/ droneunit/Dockerfile.debian:wheezy  => quay.io/dennybaa/droneunit-debian:wheezy
#

BUILD_DIR=.
BUILD_OPTS=
TEMP=`getopt -o p: -l no-cache,no-push,rm -- "$@"`
parse_status=$?

usage() {
  echo "Usage: $0 [--no-cache --no-push --rm] [-p registry prefix path ] projectdir[/Dockerfile.flavor[:label]] projectdir[/Dockerfile.flavor[:label]] ..."
  echo "\t --no-cache - Do not use cache when building the image"
  echo "\t --no-push  - Do not publish into remote repository"
  echo "\t --rm       - Remove intermediate containers after a successful build"
  echo
  echo "\t -p         - Path to remote registry including prefix, ex: quay.io/myusername/"
  echo
  echo "\t Containers found under custom Dockerfile path such as project/Dockerfile.flavor[:label]"
  echo "\t will be tagged using the following pattern {path_to_remote}{project}{flavor}:[{label}]"
  echo "\t For example command args as: '-p quay.io/dennybaa/ droneunit/Dockerfile.ubuntu:trusty'"
  echo "\t will tag image as quay.io/dennybaa/droneunit-ubuntu:trusty"
  echo
  echo "\t Forced latest tagging happens when you build image specified as projectdir/Dockerfile.flavor:mylabel"
  echo "\t and projectdir contains latest file with mylabel contents. So when image labeled as mylabel is"
  echo "\t built this image will be labeled as latest automatically."
}


# Retrieve tagname following the following convention
#   -- .../project/Dockerfile.falvor[:label]
# which maps the path to the following name project-flavor[:label]
#
tagname_from() {
  path="$1"
  dockerfile=$(basename "$path")
  project=$(basename `echo "$path" | sed -r "s/\/+$dockerfile//"`)

  flavor_label=$(echo "$dockerfile" | sed 's/.*Dockerfile\.//')
  flavor="${flavor_label%%:*}"
  label="${flavor_label##*:}"

  [ -z "$project" ] && { echo 'Dockerfile must be located under $project/ diretory'; exit 1; }

  tagname="$project"
  [ -z "$flavor" ] || tagname="${tagname}-${flavor}"
  [ -z "$label" ] || tagname="${tagname}:${label}"
  echo "$tagname"
}


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

# Execute builds
for path in $CONTAINERS; do
  build_opts="${BUILD_OPTS} -f ${path}"
  tagname=$(tagname_from "$path")
  tag="${PREFIX_PATH}${tagname}"

  # Check project/latest, if content matches current label
  # additional tagging will occur otherwise unset.
  label=$(cat `dirname "$path"`/latest 2>/dev/null)
  [ "$label" != "" -a "${tag##*:}" = "$label" ] && tag_latest=1

  # Build
  echo "Building: ${tag} (at $(readlink -f $BUILD_DIR))"
  echo '========='
  echo "docker build ${build_opts} -t ${tag} ${BUILD_DIR}"
  docker build ${build_opts} -t ${tag} ${BUILD_DIR} || continue

  # Tag latest is required
  unlabled_tag="${tag%%:*}"
  [ "$tag_latest" = 1 ] && docker tag -f ${tag} ${unlabled_tag}:latest

  # Push is required
  [ "$NO_PUSH" = 1 ] || docker push ${unlabled_tag}
done
