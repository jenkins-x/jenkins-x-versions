#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if $(cat ${IS_JX_PRERELEASE})
then
  JX_VERSION=$(sed "s:^.*jenkins-x\/jx.*\[\([0-9.]*\)\].*$:\1:;t;d" ./dependency-matrix/matrix.md)

  if [[ $JX_VERSION =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
  then
    echo "updating the CLI reference"

    pushd $(mktemp -d)
      git clone https://github.com/jenkins-x/jx-docs.git
      pushd jx-docs/content/en/docs/reference/commands
        jx create docs
        git config credential.helper store
        git add *
        git commit --allow-empty -a -m "updated jx commands & API docs from $JX_VERSION"
        
        # Note that when doing a rebase theirs and ours are swapped so -X theirs actually automatically accepts our changes in case of conflict
        git fetch origin && git rebase -X theirs origin/master
      popd

      echo "Updating the JSON Schema"
      pushd jx-docs/static
        mkdir -p schemas
        cd schemas
        jx step syntax schema -o jx-schema.json
        jx step syntax schema --requirements -o jx-requirements.json
        git add *
        git commit --allow-empty -a -m "updated jx Json Schema from $JX_VERSION"
        
        # Note that when doing a rebase theirs and ours are swapped so -X theirs actually automatically accepts our changes in case of conflict
        git fetch origin && git rebase -X theirs origin/master
      popd

      echo "Updating the JX CLI & API reference docs"

      mkdir -p ${GOPATH}/src/github.com/jenkins-x
      pushd ${GOPATH}/src/github.com/jenkins-x
        git clone https://github.com/jenkins-x/jx.git
        pushd jx
          git fetch --tags
          git checkout v${JX_VERSION}
          # make generate-refdocs needs go modules enabled. The long term solution is probably to turn it on in jx's makefile, but for the moment...
          GO111MODULE=on make generate-refdocs
        popd
      popd
      cp ${GOPATH}/src/github.com/jenkins-x/jx/docs/apidocs.md jx-docs/content/en/docs/reference/api.md
      cp ${GOPATH}/src/github.com/jenkins-x/jx/docs/config.md jx-docs/content/en/docs/reference/config

      pushd jx-docs/content/en/docs/reference
        git add *
        git commit --allow-empty -a -m "updated jx API docs from $JX_VERSION"

        # Note that when doing a rebase theirs and ours are swapped so -X theirs actually automatically accepts our changes in case of conflict
        git fetch origin && git rebase -X theirs origin/master
      popd

      pushd jx-docs
        git push origin
      popd
    popd
  fi
fi
