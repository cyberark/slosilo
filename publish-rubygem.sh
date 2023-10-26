#!/bin/bash -e
set -e

echo "==> Cloning Release-Tools GIT Repo"
git clone git@github.com:conjurinc/release-tools.git

#Add release-tools/bin to PATH
echo "==> Add $(pwd)/release-tools/bin to PATH"
export PATH=$PATH:"$(pwd)/release-tools/bin"

#then call publish_rubygems script
echo "==> Run Script: publish_rubygem "
publish_rubygem slosilo
