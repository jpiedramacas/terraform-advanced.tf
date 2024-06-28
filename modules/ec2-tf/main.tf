provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

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
  source      = "${path.module}/install_apache.sh"
  destination = "/tmp/install_apache.sh"

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/ssh.pem")
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
      private_key = file("${path.module}/ssh.pem") # Ruta completa al archivo ssh.pem
      host        = self.public_ip
    }
  }

  depends_on = [aws_security_group.web_sg]
}

# Security Group
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"

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

output "public_ip" {
  value = aws_instance.web.public_ip
}
