#!/bin/bash

set -o errexit
set -o pipefail
set -e

err_report() {
    echo "Error on line $1"
}

trap 'err_report $LINENO' ERR

START_TIME=`date +%s`

echo "Creating cluster for Testground..."
echo

my_dir="$(dirname "$0")"
source "$my_dir/install-playbook/validation.sh"

echo "Required arguments"
echo "------------------"
echo "Deployment name (DEPLOYMENT_NAME): $DEPLOYMENT_NAME"
echo "Cluster name (CLUSTER_NAME): $CLUSTER_NAME"
echo "Kops state store (KOPS_STATE_STORE): $KOPS_STATE_STORE"
echo "Cloud provider (CLOUD_PROVIDER): $CLOUD_PROVIDER"
echo "Cloud provider region (REGION): $REGION"
echo "Cloud image name (IMAGE_NAME): $IMAGE_NAME"
echo "Availability zone A (ZONE_A): $ZONE_A"
echo "Availability zone B (ZONE_B): $ZONE_B"
echo "Worker node type (WORKER_NODE_TYPE): $WORKER_NODE_TYPE"
echo "Master node type (MASTER_NODE_TYPE): $MASTER_NODE_TYPE"
echo "Worker nodes (WORKER_NODES): $WORKER_NODES"
echo "Public key (PUBKEY): $PUBKEY"
echo

if [ "$CLOUD_PROVIDER" == "aws" ]
then
  export INFRA_NODE_TYPE="c5.2xlarge"
elif [ "$CLOUD_PROVIDER" == "gce" ]
then
  export INFRA_NODE_TYPE="e2-standard-4"
  export KOPS_FEATURE_FLAGS=AlphaAllowGCE
  export GCE_PROJECT=`gcloud config get-value project`
else
  echo "Unsupported cloud provider: $CLOUD_PROVIDER"
  exit 2
fi

CLUSTER_SPEC=$(mktemp)
cat "$my_dir/cluster.yaml" "$my_dir/cluster-$CLOUD_PROVIDER.yaml" "$my_dir/instance-group.yaml" | envsubst >$CLUSTER_SPEC

# Verify with the user before continuing.
echo
echo "The cluster will be built based on the params above."
echo -n "Do they look right to you? [y/n]: "
read response

if [ "$response" != "y" ]
then
  echo "Canceling ."
  exit 2
fi

# The remainder of this script creates the cluster using the generated template

kops create -f $CLUSTER_SPEC
kops create secret --name $CLUSTER_NAME sshpublickey admin -i $PUBKEY
kops update cluster $CLUSTER_NAME --yes --admin

# Wait for worker nodes and master to be ready
kops validate cluster --wait 20m

echo "Cluster nodes are Ready"
echo

echo "Install default container limits"
echo

kubectl apply -f ./limit-range/limit-range.yaml

echo "Install Weave, CNI-Genie, Sidecar Daemonset..."
echo

kubectl apply -f ./kops-weave/weave.yml \
              -f ./kops-weave/genie-plugin.yaml \
              -f ./kops-weave/dummy.yml \
              -f ./sidecar.yaml

echo "Installing Prometheus"
pushd prometheus-operator
helm install prometheus-operator stable/prometheus-operator -f values.yaml
popd

echo "Installing InfluxDB"
pushd influxdb
# explicitly install the last version supporting InfluxDB 1.x, to align with testground/sdk-go
helm install influxdb bitnami/influxdb --version 1.1.9 -f ./values.yaml
popd


echo "Installing Redis and Grafana dashboards"
pushd testground-infra
helm dep build
helm install testground-infra .
popd

echo "Install Weave service monitor..."
echo

kubectl apply -f ./kops-weave/weave-metrics-service.yml \
              -f ./kops-weave/weave-service-monitor.yml

echo "Wait for Sidecar to be Ready..."
echo
RUNNING_SIDECARS=0
while [ "$RUNNING_SIDECARS" -ne "$WORKER_NODES" ]; do RUNNING_SIDECARS=$(kubectl get pods | grep testground-sidecar | grep Running | wc -l || true); echo "Got $RUNNING_SIDECARS running sidecar pods"; sleep 5; done;

echo "Testground cluster is installed"
echo

END_TIME=`date +%s`
echo "Execution time was `expr $END_TIME - $START_TIME` seconds"
