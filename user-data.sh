#!/bin/bash
set -ex

# Update packages
yum update -y

# Install Docker
amazon-linux-extras install -y docker
systemctl start docker
systemctl enable docker

# Install SSM Agent
if [[ "$(uname -m)" == "aarch64" ]]; then
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
else
  yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
fi
