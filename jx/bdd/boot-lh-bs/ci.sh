#!/usr/bin/env bash
set -e
set -x

export BB_USERNAME="jenkins-x-bdd"
export BB_OWNER="jxbdd"
export BB_EMAIL="jenkins-x@googlegroups.com"

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
export JX_VALUE_ADMINUSER_PASSWORD="$JENKINS_PASSWORD"
export JX_VALUE_PIPELINEUSER_USERNAME="$BB_USERNAME"
export JX_VALUE_PIPELINEUSER_EMAIL="$BB_EMAIL"
export JX_VALUE_PIPELINEUSER_TOKEN="$BB_ACCESS_TOKEN"
export JX_VALUE_PROW_HMACTOKEN="$BB_ACCESS_TOKEN"

# TODO temporary hack until the batch mode in jx is fixed...
export JX_BATCH_MODE="true"

git clone https://github.com/jenkins-x/jenkins-x-boot-config.git boot-source
cp jx/bdd/boot-lh-bs/jx-requirements.yml boot-source
cp jx/bdd/boot-lh-bs/parameters.yaml boot-source/env
cd boot-source

# TODO hack until we fix boot to do this too!
helm init --client-only
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io


jx step bdd \
    --use-revision \
    --version-repo-pr \
    --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git \
    --config ../jx/bdd/boot-lh-bs/cluster.yaml \
    --gopath /tmp \
    --git-provider bitbucketeserver \
    --git-provider-url https://bitbucket.beescloud.com \
    --git-owner $BB_OWNER \
    --git-username $BB_USERNAME \
    --git-api-token $BB_ACCESS_TOKEN \
    --default-admin-password $JENKINS_PASSWORD \
    --no-delete-app \
    --no-delete-repo \
    --tests install \
    --tests test-create-spring
