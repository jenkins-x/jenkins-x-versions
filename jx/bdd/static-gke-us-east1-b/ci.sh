#!/usr/bin/env bash
set -e
set -x

echo "BRANCH_NAME=$BRANCH_NAME"

echo "the downward API labels are:"
cat /etc/podinfo/labels

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

mkdir -p $JX_HOME

jx --version
jx step git credentials

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

jx step bdd --use-revision  --version-repo-pr --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/static-gke-us-east1-b/cluster.yaml --gopath /tmp --git-provider=ghe --git-provider-url=https://github.beescloud.com --git-username dev1 --git-api-token $GHE_ACCESS_TOKEN --default-admin-password $JENKINS_PASSWORD --no-delete-app --no-delete-repo --tests install --tests test-create-spring
