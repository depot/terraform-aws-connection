# depot/connection/aws

```tf
module "connection" {
  source        = "depot/connection/aws"
  version       = "x.x.x"
  connection-id = "xxxxxx"
  cidr-block    = "10.0.0.0/16"
  subnets = [
    { availability-zone = "us-east-1a", cidr-block = "10.0.1.0/18" },
    { availability-zone = "us-east-1b", cidr-block = "10.0.64.0/18" },
    { availability-zone = "us-east-1c", cidr-block = "10.0.128.0/18" },
  ]
}
```

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name                                                                              | Description                                                    | Type                                                                | Default         | Required |
| --------------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------- | --------------- | :------: |
| <a name="input_connection-id"></a> [connection-id](#input_connection-id)          | ID for the Depot connection (provided in the Depot console)    | `string`                                                            | n/a             |   yes    |
| <a name="input_subnets"></a> [subnets](#input_subnets)                            | Subnets to use for the VPC                                     | `list(object({ availability-zone = string, cidr-block = string }))` | n/a             |   yes    |
| <a name="input_allow-ssm-access"></a> [allow-ssm-access](#input_allow-ssm-access) | Controls if SSM access should be allowed for the EC2 instances | `bool`                                                              | `false`         |    no    |
| <a name="input_cidr-block"></a> [cidr-block](#input_cidr-block)                   | VPC CIDR block                                                 | `string`                                                            | `"10.0.0.0/16"` |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                     | A map of tags to apply to all resources                        | `map(string)`                                                       | `{}`            |    no    |

## Outputs

| Name                                                                                   | Description              | Value        | Sensitive |
| -------------------------------------------------------------------------------------- | ------------------------ | ------------ | :-------: |
| <a name="output_instance-role-arn"></a> [instance-role-arn](#output_instance-role-arn) | ARN of the instance role | `"ROLE-ARN"` |    no     |
| <a name="output_instance-role-id"></a> [instance-role-id](#output_instance-role-id)    | ID of the instance role  | `"ROLE-ID"`  |    no     |
| <a name="output_route-table-id"></a> [route-table-id](#output_route-table-id)          | VPC route table ID       | `"null"`     |    no     |
| <a name="output_vpc-id"></a> [vpc-id](#output_vpc-id)                                  | VPC ID                   | `"VPC-ID"`   |    no     |

<!-- END_TF_DOCS -->
