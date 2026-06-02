# depot/connection/aws

```tf
module "connection" {
  source              = "depot/connection/aws"
  version             = "x.x.x"
  connection-id       = "xxxxxx"
  controller-role-arn = "arn:${data.aws_partition.current.partition}:iam::123456789012:role/depot-controller-example"
  cidr-block          = "10.0.0.0/16"
  subnets = [
    { availability-zone = "us-east-1a", cidr-block = "10.0.1.0/18" },
    { availability-zone = "us-east-1b", cidr-block = "10.0.64.0/18" },
    { availability-zone = "us-east-1c", cidr-block = "10.0.128.0/18" },
  ]
}
```

## Private/customer-managed networking

```tf
module "connection" {
  source = "depot/connection/aws"

  connection-id       = "xxxxxx"
  controller-role-arn = module.controller.controller-role-arn

  vpc-id = "vpc-123"
  existing-subnets = [
    { id = "subnet-123", availability-zone = "us-gov-west-1a", cidr-block = "10.10.1.0/24" },
    { id = "subnet-456", availability-zone = "us-gov-west-1b", cidr-block = "10.10.2.0/24" },
  ]
  security-groups = {
    buildkit = "sg-123"
    default  = "sg-456"
  }

  associate-public-ip-address = false

  connection-parameter-kms-key-id = "arn:aws-us-gov:kms:us-gov-west-1:123456789012:key/..."
  volume-kms-key-id               = "arn:aws-us-gov:kms:us-gov-west-1:123456789012:key/..."
  launch-template-id              = "lt-123"
}
```

The connection metadata includes `volumeKMSKeyID` and `launchTemplateID` when `volume-kms-key-id` and `launch-template-id` are provided, so Depot can use those values when launching instances and creating EBS volumes.

## AMI-backed builder bootstrap

```tf
module "connection" {
  source = "depot/connection/aws"

  connection-id       = "xxxxxx"
  controller-role-arn = module.controller.controller-role-arn
  cidr-block          = "10.0.0.0/16"
  subnets = [
    { availability-zone = "us-east-1a", cidr-block = "10.0.1.0/18" },
    { availability-zone = "us-east-1b", cidr-block = "10.0.64.0/18" },
    { availability-zone = "us-east-1c", cidr-block = "10.0.128.0/18" },
  ]

  depot-bootstrap-mode     = "ami-tags"
  depot-builder-ami-id-x86 = "ami-123"
  depot-builder-ami-id-arm = "ami-456"
}
```

When `depot-bootstrap-mode` is `ami-tags`, Depot reads bootstrap metadata from EC2 instance tags and expects builder software to already be baked into the AMI. Provide one AMI ID per architecture that the connection should run.

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name                                                                              | Description                                                                  | Type                                                                | Default         | Required |
| --------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ------------------------------------------------------------------- | --------------- | :------: |
| <a name="input_connection-id"></a> [connection-id](#input_connection-id)          | ID for the Depot connection (provided in the Depot console)                  | `string`                                                            | n/a             |   yes    |
| <a name="input_controller-role-arn"></a> [controller-role-arn](#input_controller-role-arn) | ARN of the Depot realm controller role that can assume this connection role | `string`                                                            | n/a             |   yes    |
| <a name="input_allow-ssm-access"></a> [allow-ssm-access](#input_allow-ssm-access) | Controls if SSM access should be allowed for the EC2 instances               | `bool`                                                              | `false`         |    no    |
| <a name="input_associate-public-ip-address"></a> [associate-public-ip-address](#input_associate-public-ip-address) | Whether Depot should associate public IPs when launching instances | `bool` | `true` | no |
| <a name="input_cidr-block"></a> [cidr-block](#input_cidr-block)                   | VPC CIDR block                                                               | `string`                                                            | `"10.0.0.0/16"` |    no    |
| <a name="input_connection-parameter-kms-key-id"></a> [connection-parameter-kms-key-id](#input_connection-parameter-kms-key-id) | KMS key ID or ARN for the SSM SecureString connection metadata parameter | `string` | `null` | no |
| <a name="input_create-internet-gateway"></a> [create-internet-gateway](#input_create-internet-gateway) | Whether to create public internet routing for module-managed subnets | `bool` | `true` | no |
| <a name="input_depot-bootstrap-mode"></a> [depot-bootstrap-mode](#input_depot-bootstrap-mode) | Depot builder bootstrap mode. Use userdata for the default cloud-init bootstrap or ami-tags for builders pre-baked into the AMI. | `string` | `"userdata"` | no |
| <a name="input_depot-builder-ami-id-arm"></a> [depot-builder-ami-id-arm](#input_depot-builder-ami-id-arm) | AMI ID Depot should use for ARM builders. Required by Depot for ARM builders when depot-bootstrap-mode is ami-tags. | `string` | `null` | no |
| <a name="input_depot-builder-ami-id-x86"></a> [depot-builder-ami-id-x86](#input_depot-builder-ami-id-x86) | AMI ID Depot should use for x86 builders. Required by Depot when depot-bootstrap-mode is ami-tags. | `string` | `null` | no |
| <a name="input_existing-subnets"></a> [existing-subnets](#input_existing-subnets) | Existing subnets to use instead of creating subnets | `list(object({ id = string, availability-zone = string, cidr-block = string }))` | `[]` | no |
| <a name="input_launch-template-id"></a> [launch-template-id](#input_launch-template-id) | Launch template ID Depot should use when launching instances | `string` | `null` | no |
| <a name="input_security-groups"></a> [security-groups](#input_security-groups) | Existing security groups for Depot instances | `object({ buildkit = string, default = string })` | `null` | no |
| <a name="input_subnets"></a> [subnets](#input_subnets)                            | Subnets to create in the module-managed VPC                                  | `list(object({ availability-zone = string, cidr-block = string }))` | `[]`            |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                     | A map of tags to apply to all resources                                      | `map(string)`                                                       | `{}`            |    no    |
| <a name="input_volume-kms-key-id"></a> [volume-kms-key-id](#input_volume-kms-key-id) | KMS key ID or ARN Depot should use for launched instance root and cache/data EBS volumes | `string` | `null` | no |
| <a name="input_vpc-id"></a> [vpc-id](#input_vpc-id)                               | Existing VPC ID to use instead of creating a VPC                             | `string`                                                            | `null`          |    no    |

## Outputs

| Name                                                                                   | Description                            | Value        | Sensitive |
| -------------------------------------------------------------------------------------- | -------------------------------------- | ------------ | :-------: |
| <a name="output_connection-metadata"></a> [connection-metadata](#output_connection-metadata) | Connection metadata written for Depot | `"METADATA"` | yes |
| <a name="output_connection-controller-role-arn"></a> [connection-controller-role-arn](#output_connection-controller-role-arn) | ARN of the connection controller role | `"ROLE-ARN"` |    no     |
| <a name="output_instance-role-arn"></a> [instance-role-arn](#output_instance-role-arn) | ARN of the instance role | `"ROLE-ARN"` |    no     |
| <a name="output_instance-role-id"></a> [instance-role-id](#output_instance-role-id)    | ID of the instance role  | `"ROLE-ID"`  |    no     |
| <a name="output_route-table-id"></a> [route-table-id](#output_route-table-id)          | VPC route table ID       | `"null"`     |    no     |
| <a name="output_security-groups"></a> [security-groups](#output_security-groups)       | Security groups used by Depot instances | `"SECURITY-GROUPS"` | no |
| <a name="output_subnets"></a> [subnets](#output_subnets)                               | Subnets used by Depot instances | `"SUBNETS"` | no |
| <a name="output_vpc-id"></a> [vpc-id](#output_vpc-id)                                  | VPC ID                   | `"VPC-ID"`   |    no     |

<!-- END_TF_DOCS -->
