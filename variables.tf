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

variable "subnets" {
  type        = list(object({ availability-zone = string, cidr-block = string }))
  description = "Subnets to use for the VPC"
}

// Optional

variable "cloud-agent-version" {
  type        = string
  description = "Version tag for ghcr.io/depot/cloud-agent container"
  default     = "2"
}

variable "cloud-agent-log-retention" {
  type        = number
  description = "Number of days to keep cloudwatch logs for the cloud-agent"
  default     = 7
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

variable "cidr-block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "allow-ssm-access" {
  type        = bool
  description = "Controls if SSM access should be allowed for the builder instances"
  default     = false
}

variable "extra-env" {
  type        = list(object({ key = string, value = string }))
  description = "Extra environment variables to set on the cloud-agent"
  default     = []
}

variable "ceph-config" {
  type        = string
  description = "Ceph configuration file"
  default     = ""
}

variable "ceph-key" {
  type        = string
  description = "Ceph key file"
  default     = "none"
  sensitive   = true
}
