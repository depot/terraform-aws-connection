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
  value       = try(aws_vpc.vpc.id, "")
  description = "VPC ID"
}

output "route-table-id" {
  value       = try(aws_route_table.public.id, "")
  description = "VPC route table ID"
}
