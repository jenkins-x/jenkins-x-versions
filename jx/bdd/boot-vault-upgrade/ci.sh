#!/usr/bin/env bash
set -e
set -x

export GH_USERNAME="jenkins-x-versions-bot-test"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="jenkins-x-versions-bot-test"

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

# lets avoid the git/credentials causing confusion during the test
export XDG_CONFIG_HOME=$JX_HOME

mkdir -p $JX_HOME/git

jx --version

# replace the credentials file with a single user entry
echo "https://$GH_USERNAME:$GH_ACCESS_TOKEN@github.com" > $JX_HOME/git/credentials

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

# setup jx boot parameters
# setup jx boot parameters
export JX_REQUIREMENT_ENV_GIT_OWNER="$GH_OWNER"
export JX_REQUIREMENT_PROJECT="jenkins-x-bdd3"
export JX_REQUIREMENT_ZONE="europe-west1-c"
export JX_VALUE_ADMINUSER_PASSWORD="$JENKINS_PASSWORD"
export JX_VALUE_PIPELINEUSER_USERNAME="$GH_USERNAME"
export JX_VALUE_PIPELINEUSER_EMAIL="$GH_EMAIL"
export JX_VALUE_PIPELINEUSER_TOKEN="$GH_ACCESS_TOKEN"
export JX_VALUE_PROW_HMACTOKEN="$GH_ACCESS_TOKEN"

# TODO temporary hack until the batch mode in jx is fixed...
export JX_BATCH_MODE="true"
git clone https://github.com/jenkins-x/jenkins-x-versions.git
cd jenkins-x-versions
export PREVIOUS_JX_VERSION=$(jx step get dependency-version --host=github.com --owner=jenkins-x --repo=jx --dir . | sed 's/.*: \(.*\)/\1/')
PREVIOUS_JX_DOWNLOAD_LOCATION="https://github.com/jenkins-x/jx/releases/download/v$PREVIOUS_JX_VERSION/jx-linux-amd64.tar.gz"
cd ..

export JX_UPGRADE_VERSION_REF=$PULL_PULL_SHA
mkdir jx_download
cd jx_download
wget $PREVIOUS_JX_DOWNLOAD_LOCATION
tar -zxvf jx-linux-amd64.tar.gz
export JX_BIN_DIR=$(pwd)
export PATH=$JX_BIN_DIR:$PATH
cd ..

export BOOT_CONFIG_VERSION=$(jx step get dependency-version --host=github.com --owner=jenkins-x --repo=jenkins-x-boot-config --dir jenkins-x-versions | sed 's/.*: \(.*\)/\1/')
git clone https://github.com/jenkins-x/jenkins-x-boot-config.git boot-source
cd boot-source
cp ../jx/bdd/boot-vault-upgrade/jx-requirements.yml .
cp ../jx/bdd/boot-vault-upgrade/parameters.yaml env

# TODO hack until we fix boot to do this too!
helm init --client-only
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io

# Just run the spring-boot-http-gradle import test here
export BDD_TEST_SINGLE_IMPORT="spring-boot-http-gradle"

jx step bdd \
    --config ../jx/bdd/boot-vault-upgrade/cluster.yaml \
    --gopath /tmp \
    --git-provider=github \
    --git-username $GH_USERNAME \
    --git-owner $GH_OWNER \
    --git-api-token $GH_ACCESS_TOKEN \
    --default-admin-password $JENKINS_PASSWORD \
    --no-delete-app \
    --no-delete-repo \
    --tests install \
    --tests test-verify-pods \
    --tests test-upgrade-boot \
    --tests test-verify-pods \
    --tests test-create-spring
