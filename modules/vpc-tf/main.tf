resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "dev"
}

resource "aws_subnet" "subnet" {
  count = var.environment == "prod" ? 2 : 1

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.environment == "prod" ? element(["10.0.1.0/24", "10.0.2.0/24"], count.index) : "10.0.1.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "allow_tls" {
  name_prefix = "allow_tls_"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-01b799c439fd5516a" # Amazon Linux 2 AMI
  instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"

  subnet_id              = element(aws_subnet.subnet[*].id, 0)
  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  tags = {
    Name = "MyAppInstance"
  }

  root_block_device {
    volume_size = var.environment == "prod" ? 50 : 20
    volume_type = "gp2"
  }
}

locals {
  subnet_names = [for i in aws_subnet.subnet : "subnet-${i.availability_zone}"]
}

output "subnet_names" {
  value = local.subnet_names
}

output "subnet_ids" {
  value = aws_subnet.subnet[*].id
}
