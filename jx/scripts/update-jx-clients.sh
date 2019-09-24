#!/usr/bin/env bash

ORG_REPOS=("jenkins-x/jx-ts-client")
JX_VERSION=$(sed "s:^.*jenkins-x\/jx.*\[\([0-9.]*\)\].*$:\1:;t;d" ./dependency-matrix/matrix.md)

if [[ $JX_VERSION =~ ^[0-9]*\.[0-9]*\.[0-9]*$ ]]
then
  git clone https://github.com/jenkins-x/jx.git
  pushd jx
    git fetch --tags
    git checkout v${JX_VERSION}
    pushd docs/apidocs/openapi-spec
      SRCDIR=`pwd`
    popd
  popd
  SRC="${SRCDIR}/openapiv2.yaml"
  for org_repo in "${ORG_REPOS[@]}"; do
    OUTDIR="$(jx step git fork-and-clone -b --print-out-dir --dir=$TMPDIR https://github.com/$org_repo)"
    echo "Forked repo to $OUTDIR"
    pushd $OUTDIR
      echo "Running make all in $org_repo"
      make all
      echo "make all complete in $org_repo"
      git add -N .
      git diff --exit-code
      if [ $? -ne 0 ]
      then
        set -x
        jx create pullrequest -b --push=true --fork=true --body "upgrade $org_repo client to jx $JX_VERSION" --title "upgrade to jx $JX_VERSION" --label="updatebot"
        set +x
      else
        echo "No changes to generated code"
      fi
    popd
  done
fi
exit 0
