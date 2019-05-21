#!/usr/bin/env bash
set -e
set -x

export GH_USERNAME="jenkins-x-bot-test"
export GH_OWNER="cb-kubecd"

export GH_CREDS_PSW="$(jx step credential -s jenkins-x-bot-test-github)"
export JENKINS_CREDS_PSW="$(jx step credential -s  test-jenkins-user)"
export AWS_ACCESS_KEY_ID="$(jx step credential -s jx-bdd-aws -k AWS_ACCESS_KEY_ID)"
export AWS_SECRET_ACCESS_KEY="$(jx step credential -s jx-bdd-aws -k AWS_SECRET_ACCESS_KEY)"


# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

mkdir -p $JX_HOME

jx --version
jx step git credentials

# lets setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

jx step bdd --use-revision --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/ekstekton/cluster.yaml --gopath /tmp --git-provider=github --git-username $GH_USERNAME --git-owner $GH_OWNER --git-api-token $GH_CREDS_PSW --no-delete-app --no-delete-repo --tests install --tests test-create-spring --domain=bdd-$BUILD_NUMBER.jxbdd.beescloud.com