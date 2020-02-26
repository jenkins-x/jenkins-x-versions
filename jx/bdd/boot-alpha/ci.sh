#!/usr/bin/env bash
set -e
set -x


export PROJECT_ID=jenkins-x-bdd3
export CLUSTER_NAME="${BRANCH_NAME,,}-$BUILD_NUMBER-bdd-alpha"
export ZONE=europe-west1-c

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
jx ns jx


#helm init --client-only
#helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io

# Just run the node-http import test here
export BDD_TEST_SINGLE_IMPORT="node-http"

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
