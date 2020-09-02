#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

JX_RELEASES_URL="https://api.github.com/repos/jenkins-x/jx/releases/tags"
JX_VERSION=$(jx version --short|sed "s:Version \(.*\):\1:")

if [[ $JX_VERSION =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
then
  curl -s ${JX_RELEASES_URL}/v${JX_VERSION} | jq -r '.prerelease' > ${IS_JX_PRERELEASE}
fi

