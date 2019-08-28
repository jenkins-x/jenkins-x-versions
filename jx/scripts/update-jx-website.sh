#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ ! -z $JX_VERSION ]
then
  echo "updating the CLI reference"
  git clone https://github.com/jenkins-x/jx-docs.git
  
  pushd jx-docs/content/commands
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
  git clone https://github.com/jenkins-x/jx.git
  git fetch --tags
  git checkout v${JX_VERSION}
  pushd jx
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
