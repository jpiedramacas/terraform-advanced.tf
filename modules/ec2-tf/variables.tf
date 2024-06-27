variable "environment" {
  description = "The environment to deploy to"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "unique_suffix" {
  description = "A unique suffix for resource names"
  type        = string
}
