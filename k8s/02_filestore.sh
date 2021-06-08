#!/bin/bash

set -o errexit
set -o pipefail
set -e

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

START_TIME=`date +%s`

my_dir="$(dirname "$0")"
source "$my_dir/install-playbook/validation.sh"

echo "Installing GFS..."

pushd filestore-terraform

# create Filestore instance
terraform init -backend-config=bucket="${KOPS_STATE_STORE:5:100}" \
               -backend-config=prefix=${DEPLOYMENT_NAME}-filestore

terraform apply -var project="testground-textile" -var region=$REGION -var zone=$ZONE_A -auto-approve

popd

kubectl apply -f ./filestore/manifest.yaml.spec
