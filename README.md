# depot/connection/aws

```tf
module "connection" {
  source            = "depot/connection/aws"
  version           = "x.x.x"
  name              = "connection-name"
  connection-id     = "xxxxxx"
  api-token         = "xxxxxx"
  availability-zone = "us-east-1a"
}
```

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name                                                                                 | Description                                                        | Type                                     | Default                                                            | Required |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------ | ---------------------------------------- | ------------------------------------------------------------------ | :------: |
| <a name="input_availability-zone"></a> [availability-zone](#input_availability-zone) | Availability zone to use for the builder instances                 | `string`                                 | n/a                                                                |   yes    |
| <a name="input_connection-id"></a> [connection-id](#input_connection-id)             | ID for the Depot connection (provided in the Depot console)        | `string`                                 | n/a                                                                |   yes    |
| <a name="input_connection-token"></a> [connection-token](#input_connection-token)    | API token for the Depot connection (provided in the Depot console) | `string`                                 | n/a                                                                |   yes    |
| <a name="input_allow-ssm-access"></a> [allow-ssm-access](#input_allow-ssm-access)    | Controls if SSM access should be allowed for the builder instances | `bool`                                   | `false`                                                            |    no    |
| <a name="input_create"></a> [create](#input_create)                                  | Controls if Depot connection resources should be created           | `bool`                                   | `true`                                                             |    no    |
| <a name="input_instance-types"></a> [instance-types](#input_instance-types)          | Instance types to use for the builder instances                    | `object({ x86 = string, arm = string })` | <pre>{<br> "arm": "c6g.xlarge",<br> "x86": "c6i.xlarge"<br>}</pre> |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                        | A map of tags to apply to all resources                            | `map(string)`                            | `{}`                                                               |    no    |
| <a name="input_vpc-cidr-prefix"></a> [vpc-cidr-prefix](#input_vpc-cidr-prefix)       | VPC CIDR prefix                                                    | `string`                                 | `"10.0"`                                                           |    no    |

## Outputs

| Name                                                                                                           | Description                                        | Value       | Sensitive |
| -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ----------- | :-------: |
| <a name="output_autoscaling-group-arn-arm"></a> [autoscaling-group-arn-arm](#output_autoscaling-group-arn-arm) | Autoscaling group ARN for the ARM Depot connection | `"ASG-ARN"` |    no     |
| <a name="output_autoscaling-group-arn-x86"></a> [autoscaling-group-arn-x86](#output_autoscaling-group-arn-x86) | Autoscaling group ARN for the x86 Depot connection | `"ASG-ARN"` |    no     |
| <a name="output_vpc-id"></a> [vpc-id](#output_vpc-id)                                                          | Builder VPC ID                                     | `"VPC-ID"`  |    no     |

<!-- END_TF_DOCS -->
