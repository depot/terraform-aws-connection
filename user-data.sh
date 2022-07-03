#!/bin/bash
set -ex

yum update -y
amazon-linux-extras install -y docker
systemctl start docker
systemctl enable docker
