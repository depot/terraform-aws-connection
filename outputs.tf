output "role-arm" {
  value       = try(aws_iam_role.depot[0].name, "")
  description = "IAM role for the Depot connection"
}

output "autoscaling-group-arn-arm" {
  value       = try(aws_autoscaling_group.arm[0].arn, "")
  description = "Autoscaling group ARN for the ARM Depot connection"
}

output "autoscaling-group-arn-x86" {
  value       = try(aws_autoscaling_group.arm[0].arn, "")
  description = "Autoscaling group ARN for the x86 Depot connection"
}

output "vpc-id" {
  value       = try(aws_vpc.vpc[0].id, "")
  description = "Builder VPC ID"
}
