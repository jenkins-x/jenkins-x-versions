#!/usr/bin/env bash
set -e
set -x

export GH_OWNER="jenkins-x"
export GH_REPO="jx"
export DEPENDENCY_MATRIX="dependency-matrix/matrix.md"

if [ -f $DEPENDENCY_MATRIX ]
then
  JX_VERSION=$(sed "s:^.*$GH_OWNER\/$GH_REPO.*\[\([0-9.]*\)\].*$:\1:;t;d" ../jenkins-x-platform/$DEPENDENCY_MATRIX)
  if [ ! -z $JX_VERSION ]
  then
    jx step update release-status github --owner $GH_OWNER --repository $GH_REPO --version $JX_VERSION --prerelease=false
  fi
fi
