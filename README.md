# Testground infrastructure

This repo contains scripts for setting up a Kubernetes cluster for [Testground](https://docs.testground.ai).

## Using these scripts

Documentation and step-by-step guides on how to use these infrastructure playbooks, the `cluster:k8s` runner, and more, can be found on the [Testground documentation website](http://docs.testground.ai/). 

## Background

The `cluster:k8s` runner of Testground enables you to test distributed/p2p systems at scale. It is capable of launching test workloads comprising 10k+ instances, and we aim to reach 100k at some point.

The [IPFS](https://ipfs.io/) and [libp2p](https://libp2p.io/) projects have used these scripts and playbooks to deploy large-scale test infrastructure. By crafting test scenarios that exercise components at such scale, we have been able to run simulations, carry out attacks, perform benchmarks, and execute all kinds of tests to validate correctness and performance.

## Deploy on GCE

Firstly you need to have google cloud tools being set up.
```
brew install --cask google-cloud-sdk
gcloud init
gcloud config set project testground-textile
gcloud auth application-default login
gsutil mb gs://<repo> # testground-textile

```

Then define the required envvars
```
export KOPS_FEATURE_FLAGS=AlphaAllowGCE
export KUBE_CONFIG_PATH=~/.kube/config

export CLUSTER_NAME=testground.k8s.local
export DEPLOYMENT_NAME=testground
export KOPS_STATE_STORE=gs://testground-textile
export CLOUD_PROVIDER=gce
export GCE_PROJECT=testground-textile
export IMAGE_NAME=packer-1621905424
export REGION=us-east4
export ZONE_A=us-east4-a
export ZONE_B=us-east4-b
export WORKER_NODES=1
export MASTER_NODE_TYPE=n1-standard-1
export WORKER_NODE_TYPE=n1-standard-4
export PUBKEY=$HOME/.ssh/testground_rsa.pub
export TEAM=Textile
export PROJECT=Testground
```

Under `k8s` directory, there are shell scripts for AWS and GCE respectively. For GCE:
```
./01_install_k8s.sh
./02_filestore.sh
./03_pd.sh
./04_testground_daemon.sh
```

If you are lucky enough, the cluser should be able to be up and running. Then you should have corresponding `.env.toml` under $TESTGROUNDHOME for the testground daemon to upload the image and deploy k8s pods to run the tests.
```
["dockerhub"]
username="<...>"
access_token="<...>"
repo="<...>"

[runners."cluster:k8s"]
run_timeout_min             = 10
testplan_pod_cpu            = "100m"
testplan_pod_memory         = "100Mi"
collect_outputs_pod_cpu     = "100m"
collect_outputs_pod_memory  = "100Mi"
autoscaler_enabled          = false
provider = "dockerhub"
sysctls = [
  "net.core.somaxconn=10000",
]
```

## Contribute

Our work is never finished. If you see anything we can do better, file an issue on [github.com/testground/testground](https://github.com/testground/testground) repo or open a PR!

## License

Dual-licensed: [MIT](./LICENSE-MIT), [Apache Software License v2](./LICENSE-APACHE), by way of the [Permissive License Stack](https://protocol.ai/blog/announcing-the-permissive-license-stack/).
