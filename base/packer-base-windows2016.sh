#!/bin/bash

# ami-ee576c8d Microsoft Windows Server 2016 Base

packer -version || true

AWS_REGIONNAME="ap-southeast-2"
# Generate a unique identified for this build. UUID is the easiest
uuid=$(date +"%s")

packer build \
  -var "soe_version=0.0.2" \
  -var "build_number=3" \
  -var "build_uuid=${uuid}" \
  -var "aws_source_ami=ami-ee576c8d" \
  -var "aws_instance_type=t2.medium" \
  -var "aws_instance_profile=packer-windows" \
  -var "aws_region=ap-southeast-2"
  packer-base-windows2016.json
