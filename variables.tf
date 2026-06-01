// Required

variable "connection-id" {
  type        = string
  description = "ID for the Depot connection (provided in the Depot console)"
}

variable "subnets" {
  type        = list(object({ availability-zone = string, cidr-block = string }))
  description = "Subnets to create in the module-managed VPC"
  default     = []
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

variable "vpc-id" {
  type        = string
  description = "Existing VPC ID to use instead of creating a VPC"
  default     = null
}

variable "existing-subnets" {
  type        = list(object({ id = string, availability-zone = string, cidr-block = string }))
  description = "Existing subnets to use instead of creating subnets"
  default     = []
}

variable "route-table-id" {
  type        = string
  description = "Existing route table ID to include in Depot connection metadata"
  default     = null
}

variable "create-internet-gateway" {
  type        = bool
  description = "Whether to create an internet gateway and default route for module-managed subnets"
  default     = true
}

variable "map-public-ip-on-launch" {
  type        = bool
  description = "Whether module-created subnets should map public IPs on launch"
  default     = true
}

variable "associate-public-ip-address" {
  type        = bool
  description = "Whether Depot should associate a public IP address when launching instances"
  default     = true
}

variable "allow-ssm-access" {
  type        = bool
  description = "Controls if SSM access should be allowed for the EC2 instances"
  default     = false
}

variable "security-groups" {
  type        = object({ buildkit = string, default = string })
  description = "Existing security groups for Depot instances. When null, the module creates security groups."
  default     = null
}

variable "buildkit-ingress-cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach BuildKit instances on TCP/443 when the module creates security groups"
  default     = ["0.0.0.0/0"]
}

variable "buildkit-egress-cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks allowed for BuildKit instance egress when the module creates security groups"
  default     = ["0.0.0.0/0"]
}

variable "default-egress-cidr-blocks" {
  type        = list(string)
  description = "CIDR blocks allowed for default instance egress when the module creates security groups"
  default     = ["0.0.0.0/0"]
}

variable "flow-log-destination-arn" {
  type        = string
  description = "Destination ARN for VPC flow logs. When null, flow logs are not created."
  default     = null
}

variable "flow-log-destination-type" {
  type        = string
  description = "Destination type for VPC flow logs"
  default     = "cloud-watch-logs"
}

variable "flow-log-traffic-type" {
  type        = string
  description = "Traffic type captured by VPC flow logs"
  default     = "ALL"
}

variable "flow-log-iam-role-arn" {
  type        = string
  description = "IAM role ARN for CloudWatch Logs flow log delivery"
  default     = null
}

variable "connection-parameter-type" {
  type        = string
  description = "SSM parameter type for connection metadata"
  default     = "String"

  validation {
    condition     = contains(["String", "SecureString"], var.connection-parameter-type)
    error_message = "connection-parameter-type must be String or SecureString."
  }
}

variable "connection-parameter-kms-key-id" {
  type        = string
  description = "KMS key ID or ARN for the SSM SecureString connection metadata parameter"
  default     = null
}

variable "root-volume-kms-key-id" {
  type        = string
  description = "KMS key ID or ARN Depot should use for launched instance root volumes"
  default     = null
}

variable "cache-volume-kms-key-id" {
  type        = string
  description = "KMS key ID or ARN Depot should use for cache/data volumes"
  default     = null
}

variable "launch-template-id" {
  type        = string
  description = "Launch template ID Depot should use when launching instances"
  default     = null
}
