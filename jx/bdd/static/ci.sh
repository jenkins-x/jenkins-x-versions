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

# lets avoid the git/credentials causing confusion during the test
export XDG_CONFIG_HOME=$JX_HOME

mkdir -p $JX_HOME/git

jx --version

# replace the credentials file with a single user entry
echo "https://dev1:$GHE_ACCESS_TOKEN@github.beescloud.com" > $JX_HOME/git/credentials

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

# Disable checking that the PipelineActivity has been updated by the build controller properly, since we're not using the build controller with static masters.
export BDD_DISABLE_PIPELINEACTIVITY_CHECK=true

echo "running the BDD tests with JX_HOME = $JX_HOME"

jx step bdd --use-revision  --version-repo-pr --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/static/cluster.yaml --gopath /tmp --git-provider=ghe --git-provider-url=https://github.beescloud.com --git-username dev1 --git-api-token $GHE_ACCESS_TOKEN --default-admin-password $JENKINS_PASSWORD --no-delete-app --no-delete-repo --tests install --tests test-create-spring
