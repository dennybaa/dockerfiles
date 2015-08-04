#!/bin/bash
#
set -e

script_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
usage=$(cat <<HDE

Usage: $0 [(project | version version ... | project -- version version ...)]

Updates Dockerfile files for template projects.

Examples:
  1) ./update.sh drone-busybee
  2) ./update.sh drone-busybee -- trusty precise
  3) cd drone-busybee; ../update.sh
  4) cd drone-busybee; ../update.sh trusty jessie
HDE
)

# Change to project directory if needed
if [ "$2" = '--' ]; then
  cd "$1" && shift 2
elif [ "$2" = '' ] && [ -f "$1/Dockerfile.template" ] ; then
  cd "$1" && shift
fi


# Retrieve specific dist and it's version
# jessie -> debian, centos7 -> centos, fedora21 -> fedora
get_dist_version() {
  version="$1"
  version_or_dist=$(echo "$version" | sed -r 's/[0-9.]+$//')

  echo "[$version_or_dist]"

  if (cat "$script_dir/.dist" | grep -q "^${version_or_dist}:"); then
    # given variable is a version, such as wheezy or jessie
    version="${version_or_dist}"
    dist=$(grep "${version}" | sed 's/:.*//')

  elif (cat "$script_dir/.dist" | grep -q ":.*${version_or_dist}"); then
    # given variable is a dist, such as fedora or centos
    dist=$(cat "$script_dir/.dist" | grep ":.*${version_or_dist}" | sed 's/:.*//')
    version="${version_or_dist##$dist}"
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

  if [ -z "$dist" ]; then
    echo >&2 "error: cannot determine repo for '$version'"
    echo "$usage"
    exit 1
  fi

  variants=$(cat .variants 2>/dev/null | grep "${version}" | sed 's/:.*//' || true)
  for variant in '' $variants; do
    src="Dockerfile.template${variant:+-$variant}"
    trg="$version${variant:+/$variant}/Dockerfile"
    mkdir -p "$(dirname "$trg")"
    ( set -x && sed '
      s!DIST!'"$dist"'!g;
      s!SUITE!'"$version"'!g;
    ' "$src" > "$trg" )
  done
done
