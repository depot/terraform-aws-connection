output "instance-role-arn" {
  value       = try(aws_iam_role.instance[0].arn, "")
  description = "ARN of the instance role"
}

output "instance-role-id" {
  value       = try(aws_iam_role.instance[0].id, "")
  description = "ID of the instance role"
}

output "vpc-id" {
  value       = try(aws_vpc.vpc[0].id, "")
  description = "Builder VPC ID"
}
