provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

# EC2 Instance para el servidor web
resource "aws_instance" "web" {
  ami           = "ami-01b799c439fd5516a" # AMI de Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "vockey" # Cambia esto al nombre de tu par de claves SSH

  tags = {
    Name = "WebServer"
  }

  # Define el Security Group para permitir tráfico HTTP y SSH
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  provisioner "file" {
    source      = "install_apache.sh"
    destination = "/tmp/install_apache.sh"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("ssh.pem") # Ruta a tu clave privada
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_apache.sh",
      "sudo /tmp/install_apache.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("ssh.pem")
      host        = self.public_ip
    }
  }

  depends_on = [aws_security_group.web_sg]
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

# Output public IP of web instance
output "public_ip" {
  value = aws_instance.web.public_ip
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Variable
variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = "dev"
}

# Subnets
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "subnet" {
  count = var.environment == "prod" ? 2 : 1

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.environment == "prod" ? element(["10.0.1.0/24", "10.0.2.0/24"], count.index) : "10.0.1.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Security Group for TLS
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

# EC2 Instance para la aplicación
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

# Local expressions
locals {
  subnet_names = [for i in aws_subnet.subnet : "subnet-${i.availability_zone}"]
}

# Output subnet names
output "subnet_names" {
  value = local.subnet_names
}

# Output subnet IDs
output "subnet_ids" {
  value = aws_subnet.subnet[*].id
}
