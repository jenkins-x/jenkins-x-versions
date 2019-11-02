#!/usr/bin/env bash
set -euo pipefail
set -x

export GH_USERNAME="jenkins-x-bot-test"
export GH_EMAIL="jenkins-x@googlegroups.com"
export GH_OWNER="jenkins-x-bot-test"

# fix broken `BUILD_NUMBER` env var
export BUILD_NUMBER="$BUILD_ID"

JX_HOME="/tmp/jxhome"
KUBECONFIG="/tmp/jxhome/config"

mkdir -p $JX_HOME

jx --version
jx step git credentials

# setup GCP service account
gcloud auth activate-service-account --key-file $GKE_SA

# setup git 
git config --global --add user.name JenkinsXBot
git config --global --add user.email jenkins-x@googlegroups.com

echo "running the BDD tests with JX_HOME = $JX_HOME"

# setup jx boot parameters
export JX_VALUE_ADMINUSER_PASSWORD="$JENKINS_PASSWORD"
export JX_VALUE_PIPELINEUSER_USERNAME="$GH_USERNAME"
export JX_VALUE_PIPELINEUSER_EMAIL="$GH_EMAIL"
export JX_VALUE_PIPELINEUSER_TOKEN="$GH_ACCESS_TOKEN"
export JX_VALUE_PROW_HMACTOKEN="$GH_ACCESS_TOKEN"

# TODO temporary hack until the batch mode in jx is fixed...
export JX_BATCH_MODE="true"

# prepare the BDD configuration
git clone https://github.com/jenkins-x/jenkins-x-boot-config.git boot-source
cp jx/bdd/boot-vault-tls/jx-requirements.yml boot-source
cp jx/bdd/boot-vault-tls/parameters.yaml boot-source/env
cd boot-source

# Rotate the domains to avoid cert-manager API rate limit. 
# This rotation is using # 2 domains per hour, using a "seed" of today's day-of-year to ensure a different start of
# the rotation daily.
if [[ "${DOMAIN_ROTATION}" == "true" ]]; then
    SHARD=$(date +"%l" | xargs)
    if [[ $SHARD -eq 12 ]]; then
        SHARD=0
    fi
    SHARD=$((2 * SHARD + 1))
    MIN=$(date +"%M" | xargs)
    if [[ $MIN -gt 30 ]]; then
        SHARD=$((SHARD + 1))
    fi
    DOY=$(date +"%j" | xargs)
    SHARD=$(((SHARD + DOY) % 24))
    # If we end up at 0, then roll back over to 24.
    if [[ $SHARD -eq 0 ]]; then
      SHARD=24
    fi
    DOMAIN="${DOMAIN_PREFIX}${SHARD}${DOMAIN_SUFFIX}"
    if [[ -z "${DOMAIN}" ]]; then
        echo "Domain rotation enabled. Please set DOMAIN_PREFIX and DOMAIN_SUFFIX environment variables" 
        exit -1
    fi
    echo "Using domain: ${DOMAIN}"
    sed -i "/^ *ingress:/,/^ *[^:]*:/s/domain: .*/domain: ${DOMAIN}/" jx-requirements.yml
fi
echo "Using jx-requirements.yml"
cat jx-requirements.yml

# TODO hack until we fix boot to do this too!
helm init --client-only
helm repo add jenkins-x https://storage.googleapis.com/chartmuseum.jenkins-x.io

jx step bdd \
    --use-revision \
    --version-repo-pr \
    --versions-repo https://github.com/jenkins-x/jenkins-x-versions.git \
    --config ../jx/bdd/boot-vault-tls/cluster.yaml \
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
    --tests test-app-lifecycle
