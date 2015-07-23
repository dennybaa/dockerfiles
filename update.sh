#!/bin/bash
#
set -e

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

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
  versions=( */ )
fi
versions=( "${versions[@]%/}" )


debian="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/debian')"
ubuntu="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/ubuntu-debootstrap')"

reponame=$(basename $(pwd))
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
    src="Dockerfile.template${variant:+-$variant}"
    trg="$version${variant:+/$variant}/Dockerfile"
    mkdir -p "$(dirname "$trg")"
    ( set -x && sed '
      s!DIST!'"$dist"'!g;
      s!SUITE!'"$version"'!g;
    ' "$src" > "$trg" )
  done
done
