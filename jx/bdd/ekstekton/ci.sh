#!/usr/bin/env bash
set -e
set -x

export GH_USERNAME="jenkins-x-bot-test"
export GH_OWNER="jenkins-x-bot-test"

export AWS_REGION="us-east-1"
[[ -d ~/.aws ]] || mkdir ~/.aws

echo "[default]
region = $AWS_REGION" >> ~/.aws/config
echo "[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials


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

jx step bdd --use-revision --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/ekstekton/cluster.yaml --base-domain=jxbdd.beescloud.com --gopath /tmp --git-provider=github --git-username $GH_USERNAME --git-owner $GH_OWNER --git-api-token $GH_ACCESS_TOKEN --no-delete-app --no-delete-repo --tests install --tests test-create-spring
