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
  type        = list(object({ availability-zone = string, cidr = string }))
  description = "Subnets to use for the builder instances"
}

// Optional

variable "cloud-agent-version" {
  type        = string
  description = "Version tag for ghcr.io/depot/cloud-agent container"
  default     = "2"
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
