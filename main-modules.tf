variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "dev"
}

variable "unique_suffix" {
  description = "A unique suffix for resource names"
  type        = string
  default     = "unique_id"  # Cambia esto a un ID único o variable
}

module "vpc" {
  source     = "./modules/vpc-tf"
  environment = var.environment
}

module "ec2" {
  source        = "./modules/ec2-tf"
  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.subnet_ids
  unique_suffix = var.unique_suffix  # Pasa la variable
}

output "instance_public_ip" {
  value = module.ec2.instance_public_ip
}
