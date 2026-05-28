// Required

variable "connection-id" {
  type        = string
  description = "ID for the Depot connection (provided in the Depot console)"
}

variable "subnets" {
  type        = list(object({ availability-zone = string, cidr-block = string }))
  description = "Subnets to use for the VPC"
}

variable "controller-role-arn" {
  type        = string
  description = "ARN of the Depot realm controller role that can assume this connection role"
}

// Optional

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default     = {}
}

variable "cidr-block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "allow-ssm-access" {
  type        = bool
  description = "Controls if SSM access should be allowed for the EC2 instances"
  default     = false
}
