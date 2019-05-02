#!/usr/bin/env bash
set -e
set -x

export GH_USERNAME="jenkins-x-bot-test"
export GH_OWNER="cb-kubecd"

export GH_CREDS_PSW="$(jx step credential -s jenkins-x-bot-test-github)"
export JENKINS_CREDS_PSW="$(jx step credential -s  test-jenkins-user)"
export GKE_SA="$(jx step credential -k bdd-credentials.json -s bdd-secret -f sa.json)"

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

jx --version
jx step git credentials

gcloud auth activate-service-account --key-file $GKE_SA

# lets setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

mkdir $JX_HOME || echo "JX Home already existed"

# most users may have an existing configuration - so set this to something valid (but missing) so things should break if they can not be found stuff (e.g. picking up the incorrect namespace)
# or maybe we should set things to a valid jx install and make sure we do not pick up things instead?
cat << EOF > $KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://localhost:666
  name: non-existant-cluster
contexts:
- context:
    cluster: docker-for-desktop-cluster
    namespace: default
    user: non-existant-cluster
  name: non-existant-context
current-context: non-existant-context
kind: Config
preferences: {}
EOF


jx step bdd --use-revision --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git --config jx/bdd/ng/cluster.yaml --gopath /tmp --git-provider=github --git-username $GH_USERNAME --git-owner $GH_OWNER --git-api-token $GH_CREDS_PSW --default-admin-password $JENKINS_CREDS_PSW --no-delete-app --no-delete-repo --tests install --tests test-create-spring