#!/usr/bin/env bash
set -e
set -x

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

# lets avoid the git/credentials causing confusion during the test
export XDG_CONFIG_HOME=$JX_HOME
mkdir -p $JX_HOME/git

jx --version

export GH_USERNAME="jenkins-x-versions-bot-test"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="jenkins-x-versions-bot-test"

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

# replace the credentials file with a single user entry
echo "https://$GH_USERNAME:$GH_ACCESS_TOKEN@github.com" > $JX_HOME/git/credentials


# lets create a new GKE cluster
export PROJECT_ID=jenkins-x-bdd3
export CLUSTER_NAME="$BRANCH_NAME-$BUILD_ID-bdd-alpha"
export ZONE=europe-west1-c

git clone https://github.com/jenkins-x-charts/jenkins-x-installer
jenkins-x-installer/create_cluster.sh


echo "using the version stream ref: $PULL_PULL_SHA"

## create the boot git repository
jxl boot create --provider=gke --version-stream-ref=$PULL_PULL_SHA --env-git-owner=$GH_OWNER --out giturl.txt


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

jxl boot import -f /tmp/secrets.yaml

# run boot
echo running: jxl boot run --git-url `cat giturl.txt`

jxl boot run --git-url `cat giturl.txt`