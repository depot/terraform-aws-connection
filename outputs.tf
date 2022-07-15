output "vpc-id" {
  value       = try(aws_vpc.vpc[0].id, "")
  description = "Builder VPC ID"
}
