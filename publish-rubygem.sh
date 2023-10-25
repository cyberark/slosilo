               
#!/usr/bin/env bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: $0 <project>"
  exit 1
fi

project="${1}"

if [ ! -f "${project}.gemspec" ]; then
  echo "Cannot find ${project}.gemspec"
  echo "Usage: $0 <project>"
  exit 1
fi

base="$(dirname "${0}")"

git clone git@github.com:conjurinc/release-tools.git

docker run \
  --rm \
  --env RUBYGEMS_API_KEY \
  --volume "$(pwd)":"$(pwd)" \
  --workdir "$(pwd)" \
  cyberark/ubuntu-ruby-builder:latest \
  "${base}/release-tools/build_and_run" "${project}"

#  "${base}/publish-rubygem-container-entrpoint.sh" "${project}"


#OLD
#!/bin/bash -e
#
#docker pull registry.tld/conjurinc/publish-rubygem
#
#git clean -fxd
#
#summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
#  docker run --rm --env-file @SUMMONENVFILE -v "$(pwd)":/opt/src \
#  registry.tld/conjurinc/publish-rubygem slosilo
#
#git clean -fxd
