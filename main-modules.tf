provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

module "ec2" {
  source = "./modules/ec2-tf"
}

module "vpc" {
  source = "./modules/vpc-tf"
}

output "web_instance_id" {
  value = module.ec2.web_instance_id
}

output "web_public_ip" {
  value = module.ec2.public_ip
}
