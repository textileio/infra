build-ami-image:
	packer build -var 'source_ami=ami-0ed4a9453b39ea8c1' -var 'aws_region=eu-west-2' testground-ami.json
build-gcp-image:
	packer build -var 'gcp_zone=us-east4-a' testground-gcp.json
