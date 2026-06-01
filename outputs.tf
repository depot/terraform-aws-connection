output "instance-role-arn" {
  value       = try(aws_iam_role.instance.arn, "")
  description = "ARN of the instance role"
}

output "instance-role-id" {
  value       = try(aws_iam_role.instance.id, "")
  description = "ID of the instance role"
}

output "connection-controller-role-arn" {
  value       = try(aws_iam_role.controller.arn, "")
  description = "ARN of the connection controller role"
}

output "vpc-id" {
  value       = local.vpc_id
  description = "VPC ID"
}

output "route-table-id" {
  value       = local.route_table_id
  description = "VPC route table ID"
}

output "security-groups" {
  value       = local.security_groups
  description = "Security groups used by Depot instances"
}

output "subnets" {
  value = [
    for subnet in local.subnets : {
      id               = subnet.id
      availabilityZone = subnet.availabilityZone
      cidrBlock        = subnet.cidrBlock
    }
  ]
  description = "Subnets used by Depot instances"
}

output "connection-metadata" {
  value       = jsondecode(aws_ssm_parameter.connection.value)
  description = "Connection metadata written for Depot"
  sensitive   = true
}
