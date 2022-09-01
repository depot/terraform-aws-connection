// Required

variable "connection-id" {
  type        = string
  description = "ID for the Depot connection (provided in the Depot console)"
}

variable "connection-token" {
  type        = string
  description = "API token for the Depot connection (provided in the Depot console)"
  sensitive   = true
}

variable "availability-zone" {
  type        = string
  description = "Availability zone to use for the builder instances"
}

// Optional

variable "cloud-agent-version" {
  type        = string
  description = "Version tag for ghcr.io/depot/cloud-agent container"
  default     = "1.2.0"
}

variable "create" {
  type        = bool
  description = "Controls if Depot connection resources should be created"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to all resources"
  default     = {}
}

variable "instance-types" {
  type        = object({ x86 = string, arm = string })
  description = "Instance types to use for the builder instances"
  default     = { x86 = "c6i.xlarge", arm = "c6g.xlarge" }
}

variable "vpc-cidr-prefix" {
  type        = string
  description = "VPC CIDR prefix"
  default     = "10.0"
}

variable "allow-ssm-access" {
  type        = bool
  description = "Controls if SSM access should be allowed for the builder instances"
  default     = false
}
