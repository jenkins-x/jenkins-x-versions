#!/usr/bin/env bash
set -e
set -x

export GH_USERNAME="jenkins-x-bot-test"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="cb-kubecd"

export GH_CREDS_PSW="$(jx step credential -s jenkins-x-bot-test-github)"
export JENKINS_CREDS_PSW="$(jx step credential -s  test-jenkins-user)"
export GKE_SA="$(jx step credential -k bdd-credentials.json -s bdd-secret -f sa.json)"

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

# setup jx boot parameters
export JX_VALUE_ADMINUSER_PASSWORD="$JENKINS_CREDS_PSW"
export JX_VALUE_PIPELINEUSER_EMAIL="$GH_EMAIL"
export JX_VALUE_PIPELINEUSER_USERNAME="$GH_USERNAME"
export JX_VALUE_PIPELINEUSER_TOKEN="$GH_CREDS_PSW"
export JX_VALUE_PROW_HMACTOKEN="$GH_CREDS_PSW"

# TODO temporary hack until the batch mode in jx is fixed...
export JX_BATCH_MODE="true"

git clone https://github.com/jenkins-x/jenkins-x-boot-config.git boot-source
cp jx/bdd/devpods/jx-requirements.yml boot-source
cp jx/bdd/devpods/parameters.yaml boot-source/env
cd boot-source

# TODO hack until we fix boot to do this too!
helm init --client-only
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io

jx step bdd \
    --use-revision \
    --version-repo-pr \
    --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git \
    --config ../jx/bdd/devpods/cluster.yaml \
    --gopath /tmp \
    --git-provider=github \
    --git-username $GH_USERNAME \
    --git-owner $GH_OWNER \
    --git-api-token $GH_CREDS_PSW \
    --default-admin-password $JENKINS_CREDS_PSW \
    --no-delete-app \
    --no-delete-repo \
    --tests install \
    --tests test-devpod
