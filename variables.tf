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

variable "connection-parameter-kms-key-id" {
  type        = string
  description = "KMS key ID or ARN for the SSM SecureString connection metadata parameter"
  default     = null
}

variable "volume-kms-key-id" {
  type        = string
  description = "KMS key ID or ARN Depot should use for launched instance root and cache/data EBS volumes"
  default     = null
}

variable "launch-template-id" {
  type        = string
  description = "Launch template ID Depot should use when launching instances"
  default     = null
}

variable "extra-tags" {
  type        = map(string)
  description = "Additional AWS tags Depot should apply to launched builder instances and root volumes"
  default     = {}
}

variable "depot-builder-ami-id-x86" {
  type        = string
  description = "AMI ID Depot should use for x86 builders"
  default     = null
}

variable "depot-builder-ami-id-arm" {
  type        = string
  description = "AMI ID Depot should use for ARM builders"
  default     = null
}
