#!/usr/bin/env bash
set -e
set -x

# setup environment
JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

# lets avoid the git/credentials causing confusion during the test
export XDG_CONFIG_HOME=$JX_HOME
mkdir -p $JX_HOME/git

jx --version

export GH_USERNAME="jenkins-x-versions-bot-test"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="jenkins-x-versions-bot-test"

# lets setup git
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

# replace the credentials file with a single user entry
echo "https://$GH_USERNAME:$GH_ACCESS_TOKEN@github.com" > $JX_HOME/git/credentials


# lets create a new GKE cluster
gcloud auth activate-service-account --key-file $GKE_SA

export CREATED_TIME=$(date '+%a-%b-%d-%Y-%H-%M-%S')
export PROJECT_ID=jenkins-x-bdd3
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-bdd-alpha"
export ZONE=europe-west1-c
export LABELS="branch=${BRANCH_NAME,,},cluster=bdd-boot-alpha,create-time=${CREATED_TIME,,}"

echo "creating cluster $CLUSTER_NAME with labels $LABELS"

git clone https://github.com/jenkins-x-charts/jenkins-x-installer
jenkins-x-installer/create_cluster.sh


echo "using the version stream ref: $PULL_PULL_SHA"

# create the boot git repository
jxl boot create -b --provider=gke --version-stream-ref=$PULL_PULL_SHA --env-git-owner=$GH_OWNER --project=$PROJECT_ID --cluster=$CLUSTER_NAME --zone=$ZONE --out giturl.txt


# import secrets...
echo "secrets:
  adminUser:
    username: admin
    password: $JENKINS_PASSWORD
  hmacToken: $GH_ACCESS_TOKEN
  pipelineUser:
    username: $GH_USERNAME
    token: $GH_ACCESS_TOKEN
    email: $GH_EMAIL" > /tmp/secrets.yaml

jxl boot secrets import -f /tmp/secrets.yaml

# run the boot Job
echo running: jxl boot run -b --git-url `cat giturl.txt`

jxl boot run -b --git-url `cat giturl.txt` --job


# lets make sure jx defaults to helm3
export JX_HELM3="true"

jx ns jx

# TODO not sure we need this?
helm init
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io

# Just run the node-http import test here
export BDD_TEST_SINGLE_IMPORT="node-http"


# lets run the BDD tests
jx step bdd \
    --use-revision \
    --version-repo-pr \
    --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git \
    --use-current-team \
    --gopath /tmp \
    --git-provider=github \
    --git-username $GH_USERNAME \
    --git-owner $GH_OWNER \
    --git-api-token $GH_ACCESS_TOKEN \
    --default-admin-password $JENKINS_PASSWORD \
    --no-delete-app \
    --no-delete-repo \
    --tests install \
    --tests test-create-spring \
    --tests test-single-import
