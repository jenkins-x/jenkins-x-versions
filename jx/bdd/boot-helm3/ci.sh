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
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-bdd-boot-helm3"
export ZONE=europe-west1-c
export LABELS="branch=${BRANCH_NAME,,},cluster=bdd-boot-helm3,create-time=${CREATED_TIME,,}"

echo "creating cluster $CLUSTER_NAME with labels $LABELS"

git clone https://github.com/jenkins-x-labs/cloud-resources.git
cloud-resources/gcloud/create_cluster.sh


# TODO remove once we remove the code from the multicluster branch of jx:
export JX_SECRETS_YAML=/tmp/secrets.yaml

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

jxl boot secrets import -f /tmp/secrets.yaml --git-url `cat giturl.txt`

# run the boot Job
echo running: jxl boot run -b --git-url `cat giturl.txt`

jxl boot run -b --git-url `cat giturl.txt` --job


# lets make sure jx defaults to helm3
export JX_HELM3="true"

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
jx ns jx

# diagnostic commands to test the image's kubectl
kubectl version

# for some reason we need to use the full name once for the second command to work!
kubectl get environments
kubectl get env
kubectl get env dev -oyaml

# TODO not sure we need this?
helm init
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io


export JX_DISABLE_DELETE_APP="true"

export GIT_ORGANISATION="$GH_OWNER"


# run the BDD tests
bddjx -ginkgo.focus=golang -test.v
