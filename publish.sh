#!/bin/bash
#
BUILD_OPTS=
TEMP=`getopt -o p: -l "no-cache,no-push,rm,cd" -- "$@"`
parse_status=$?

set -e

usage=$(cat <<HDE

Usage: $0 [--no-cache --no-push --rm] [-p registry prefix] [(project | version version ... | project -- version version ...)]
    
Builds and pushes image to a remote registry.

  --no-cache    - Do not use cache when building the image
  --no-push     - Do not push image to a remote registry after a successful build
  --rm          - Remove intermediate containers after a successful build.

  -p registry prefix - Specifies registry prefix for an image which is being built and pushed.

Examples:
  1) ./publish.sh -p quay.io/dennybaa/ drone-busybee
  2) ./publish.sh -p quay.io/dennybaa/ drone-busybee -- trusty precise
  3) cd drone-busybee; ../publish.sh -p quay.io/dennybaa/
  4) cd drone-busybee; ../publish.sh -p quay.io/dennybaa/ trusty jessie
HDE
)

# Parse check
[ "0" != $parse_status ] && { echo "$usage" && exit $parse_status; }

# extract options and their arguments into variables.
while true ; do
  case "$1" in
    -p)
      REGPATH=$2; shift 2;;
    --no-cache)
      BUILD_OPTS="${BUILD_OPTS} --no-cache"; shift;;
    --no-push)
      NO_PUSH=1; shift;;
    --rm)
      BUILD_OPTS="${BUILD_OPTS} --rm"; shift;;
    *) break;;
  esac
done

# Change to project directory if needed
if [ "$2" = '--' ]; then
  cd "$1" && shift 2
elif [ "$2" = '' ] && [ -f "$1/Dockerfile.template" ] ; then
  cd "$1" && shift
fi

reponame=$(basename $(pwd))

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )

debian="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/debian')"
ubuntu="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/ubuntu-debootstrap')"

for version in "${versions[@]}"; do
  if [ -f "$version/.skipdist" ]; then
    :
  elif echo "$debian" | grep -q "$version:"; then
    dist='debian'
  elif echo "$ubuntu" | grep -q "$version:"; then
    dist='ubuntu-debootstrap'
  else
    echo >&2 "error: cannot determine repo for '$version'"
    echo "$usage"
    exit 1
  fi

  variants=$(cat .variants 2>/dev/null | grep "${version}" | sed 's/:.*//' || true)
  for variant in $variants ''; do
    df="$version${variant:+/$variant}/Dockerfile"
    tag="${REGPATH}${reponame}:${version}${variant:+-$variant}"

    # Build image
    docker build $BUILD_OPTS -f "$df" -t "${tag}" .

    # Tag the latest image when main variant is processed
    latest=$(cat .latest 2>/dev/null || true)
    if [ -z "$variant" ] && [ "$version" = "$latest" ] ; then
      docker tag -f "$tag" "${REGPATH}${reponame}:latest"
      docker push "${REGPATH}${reponame}:latest"
    fi

    # Push image
    docker push "$tag"
  done
done
