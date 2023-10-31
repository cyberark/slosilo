#!/bin/bash -e
set -e

# Scripted pipeline
#def buildNumber = currentBuild.number

# Declarative pipeline
#echo "==> Build number is ${currentBuild.number}"

BUILDNO=%BUILD_NUMBER%
echo "==> Build Number = ${BUILDNO}"



echo "==> Cloning Release-Tools GIT Repo"
git clone git@github.com:conjurinc/release-tools.git

#Add release-tools/bin to PATH
echo "==> Add $(pwd)/release-tools/bin to PATH"
export PATH=$PATH:"$(pwd)/release-tools/bin"

#echo "==> check bin path"
#echo "${PATH}"
#ls -l "$(pwd)/release-tools/bin"


#echo "==> RUBYGEMS_API_KEY = ${RUBYGEMS_API_KEY}"

#then call publish_rubygems script
echo "==> Run Script: publish_rubygem slosilo"
#publish-rubygem slosilo
summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  publish-rubygem slosilo
