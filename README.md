# depot/depot-connection/aws

<!-- BEGIN_TF_DOCS -->

## Inputs

| Name                                                                                 | Description                                                          | Type                                     | Default                                                                                  | Required |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------------------- | :------: |
| <a name="input_availability-zone"></a> [availability-zone](#input_availability-zone) | Availability zone to use for the builder instances                   | `string`                                 | n/a                                                                                      |   yes    |
| <a name="input_external-id"></a> [external-id](#input_external-id)                   | External ID for the Depot connection (provided in the Depot console) | `string`                                 | n/a                                                                                      |   yes    |
| <a name="input_name"></a> [name](#input_name)                                        | Name of the Depot connection                                         | `string`                                 | n/a                                                                                      |   yes    |
| <a name="input_ami"></a> [ami](#input_ami)                                           | AMIs to use for the builder instances                                | `object({ x86 = string, arm = string })` | <pre>{<br> "arm": "ami-0432a829da4fa3770",<br> "x86": "ami-0432a829da4fa3770"<br>}</pre> |    no    |
| <a name="input_create"></a> [create](#input_create)                                  | Controls if Depot connection resources should be created             | `bool`                                   | `true`                                                                                   |    no    |
| <a name="input_instance-types"></a> [instance-types](#input_instance-types)          | Instance types to use for the builder instances                      | `object({ x86 = string, arm = string })` | <pre>{<br> "arm": "c6g.xlarge",<br> "x86": "c6i.xlarge"<br>}</pre>                       |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                        | A map of tags to apply to all resources                              | `map(string)`                            | `{}`                                                                                     |    no    |
| <a name="input_vpc-cidr-prefix"></a> [vpc-cidr-prefix](#input_vpc-cidr-prefix)       | VPC CIDR prefix                                                      | `string`                                 | `"10.0"`                                                                                 |    no    |

## Outputs

| Name                                                                                                           | Description                                        | Value        | Sensitive |
| -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ------------ | :-------: |
| <a name="output_autoscaling-group-arn-arm"></a> [autoscaling-group-arn-arm](#output_autoscaling-group-arn-arm) | Autoscaling group ARN for the ARM Depot connection | `"ASG-ARN"`  |    no     |
| <a name="output_autoscaling-group-arn-x86"></a> [autoscaling-group-arn-x86](#output_autoscaling-group-arn-x86) | Autoscaling group ARN for the x86 Depot connection | `"ASG-ARN"`  |    no     |
| <a name="output_role-arm"></a> [role-arm](#output_role-arm)                                                    | IAM role for the Depot connection                  | `"ROLE-ARN"` |    no     |
| <a name="output_vpc-id"></a> [vpc-id](#output_vpc-id)                                                          | Builder VPC ID                                     | `"VPC-ID"`   |    no     |

<!-- END_TF_DOCS -->
