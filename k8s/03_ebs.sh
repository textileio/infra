#!/bin/bash

set -o errexit
set -o pipefail
set -e

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

START_TIME=`date +%s`

CLUSTER_SPEC_TEMPLATE=$1

my_dir="$(dirname "$0")"
source "$my_dir/install-playbook/validation.sh"

echo "Installing EBS..."

# extract s3 bucket from kops state store
S3_BUCKET="${KOPS_STATE_STORE:5:100}"

# create EBS volume for testground datadir
pushd ebs-terraform

terraform init -backend-config=bucket=$S3_BUCKET \
               -backend-config=key=${DEPLOYMENT_NAME}-ebs \
               -backend-config=region=$REGION

terraform apply -var aws_region=$REGION -var aws_availability_zone=${REGION}a -auto-approve

export TG_EBS_DATADIR_VOLUME_ID="`terraform output volume_id`"

popd

echo "Got volume id for Testground datadir: $TG_EBS_DATADIR_VOLUME_ID"

EBS_SPEC=$(mktemp)
envsubst <./ebs.yml.spec >$EBS_SPEC

kubectl apply -f $EBS_SPEC

echo "EBS volume for Testground daemon is ready"
echo

END_TIME=`date +%s`
echo "Execution time was `expr $END_TIME - $START_TIME` seconds"
