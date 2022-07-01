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

variable "name" {
  type        = string
  description = "Name of the Depot connection"
}

variable "external-id" {
  type        = string
  description = "External ID for the Depot connection (provided in the Depot console)"
}

variable "create-builder-instance-profile" {
  type        = bool
  description = "Create a new IAM instance profile for the builder role"
  default     = "true"
}

variable "create-vpc" {
  type        = bool
  description = "Create a new VPC"
  default     = "true"
}

variable "vpc-id" {
  type        = string
  description = "Custom VPC ID, if var.create-vpc = false"
  default     = ""
}

variable "vpc-cidr-prefix" {
  type        = string
  description = "VPC CIDR prefix"
  default     = "10.0"
}
