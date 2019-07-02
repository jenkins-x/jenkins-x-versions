#!/usr/bin/env bash
set -e
set -x

export GH_OWNER="jenkins-x"
export GH_REPO="jx"
export GITHUB_ACCESS_TOKEN="$(cat /builder/home/git-token 2> /dev/null)"

VERSION=$1
RELEASE_ID=$(curl -f "https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/releases/tags/${VERSION}?access_token=${GITHUB_ACCESS_TOKEN}" -s | jq .id)

curl -X PATCH \
     -H 'Content-Type: application/json' \
     -d '{"prerelease": false}' \
     -f \
     "https://api.github.com/repos/cagiti/quickstart-go2/releases/${RELEASE_ID}?access_token=${GITHUB_ACCESS_TOKEN}"
