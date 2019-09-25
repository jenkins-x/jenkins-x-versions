#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

JX_VERSION=$(sed "s:^.*jenkins-x\/jx.*\[\([0-9.]*\)\].*$:\1:;t;d" ./dependency-matrix/matrix.md)

if [[ $JX_VERSION =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
then
  echo "updating the CLI reference"

  if [ ! -d ./jx-docs ]
  then
    git clone https://github.com/jenkins-x/jx-docs.git
  fi
  pushd jx-docs/content/en/docs/reference/commands
    jx create docs
    git config credential.helper store
    git add *
    git commit --allow-empty -a -m "updated jx commands & API docs from $JX_VERSION"
    git fetch origin && git rebase origin/master
  popd

  echo "Updating the JSON Schema"
  pushd jx-docs/content
    mkdir -p schemas
    cd schemas
    jx step syntax schema -o jx-schema.json
    git add *
    git commit --allow-empty -a -m "updated jx Json Schema from $JX_VERSION"
    git fetch origin && git rebase origin/master
  popd

  echo "Updating the JX CLI & API reference docs"

  if [ ! -d ./jx ]
  then
    git clone https://github.com/jenkins-x/jx.git
  fi
  pushd jx
    git fetch --tags
    git checkout v${JX_VERSION}
    make generate-docs
  popd
  cp -r jx/docs/apidocs/site ../jx-docs/static/apidocs

  pushd jx-docs/static/apidocs
    git add *
    git commit --allow-empty -a -m "updated jx API docs from $JX_VERSION"
    git fetch origin && git rebase origin/master
  popd

   pushd jx-docs
    git push origin
  popd
fi
