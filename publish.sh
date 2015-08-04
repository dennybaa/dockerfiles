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


# Retrieve specific dist and it's version
# jessie -> debian, centos7 -> centos, fedora21 -> fedora
get_dist_version() {
  version_or_dist=$(echo "$1" | sed -r 's/[0-9.]+$//')

  if (cat "$script_dir/.dist" | grep -q "^${version_or_dist}:"); then
    # given variable is a version, such as wheezy or jessie
    version="${version_or_dist}"
    dist=$(cat "$script_dir/.dist" | grep "${version}" | sed 's/:.*//')

  elif (cat "$script_dir/.dist" | grep -q ":.*${version_or_dist}"); then
    # given variable is a dist, such as fedora or centos
    dist=$(cat "$script_dir/.dist" | grep ":.*${version_or_dist}" | sed 's/:.*//')
    version="${version_or_dist##$dist}"
  fi

  if [ ! -f "$version/.notemplate" ] && [ -z "$dist" ]; then
    echo >&2 "error: cannot determine repo for '$version'"
    echo "$usage"
    exit 1
  fi

  echo "$dist" "$version"
}


versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )

reponame=$(basename $(pwd))
for version in "${versions[@]}"; do
  dist_version=($(get_dist_version "$version"))
  dist="${dist_version[0]}"
  suite="${dist_version[1]}"

  variants=$(cat .variants 2>/dev/null | grep "${version}" | sed 's/:.*//' || true)
  for variant in '' $variants; do
    df="$version${variant:+/$variant}/Dockerfile"
    tag="${REGPATH}${reponame}:${version}${variant:+-$variant}"

    # Build image
    docker build $BUILD_OPTS -f "$df" -t "${tag}" .

    # Tag the latest image when main variant is processed
    latest=$(cat .latest 2>/dev/null || true)
    if [ "$NO_PUSH" != 1 ] && [ -z "$variant" ] && [ "$version" = "$latest" ] ; then
      docker tag -f "$tag" "${REGPATH}${reponame}:latest"
      docker push "${REGPATH}${reponame}:latest"
    fi

    # Push image
    [ "$NO_PUSH" != 1 ] && docker push "$tag"
  done
done
