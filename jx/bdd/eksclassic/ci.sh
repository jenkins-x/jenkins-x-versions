#!/usr/bin/env bash
set -e
set -x

export GHE_CREDS_PSW="$(jx step credential -s jx-pipeline-git-github-ghe)"
export JENKINS_CREDS_PSW="$(jx step credential -s  test-jenkins-user)"
export AWS_ACCESS_KEY_ID="$(jx step credential -s jx-bdd-aws -k AWS_ACCESS_KEY_ID)"
export AWS_SECRET_ACCESS_KEY="$(jx step credential -s jx-bdd-aws -k AWS_SECRET_ACCESS_KEY)"
export AWS_REGION="us-east-1"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION


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

jx step bdd --use-revision --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/eksclassic/cluster.yaml --gopath /tmp --base-domain=jxbdd.beescloud.com --git-provider=ghe --git-provider-url=https://github.beescloud.com --git-username dev1 --git-api-token $GHE_CREDS_PSW --default-admin-password $JENKINS_CREDS_PSW --no-delete-app --no-delete-repo --tests install --tests test-create-spring