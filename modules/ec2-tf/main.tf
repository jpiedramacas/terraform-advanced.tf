resource "aws_instance" "web" {
  ami           = "ami-01b799c439fd5516a" # AMI de Amazon Linux 2
  instance_type = var.environment == "prod" ? "t2.medium" : "t2.micro"
  key_name      = "vockey" # Cambia esto al nombre de tu par de claves SSH
  subnet_id     = element(var.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true  # Asegúrate de que la instancia tenga una IP pública

  provisioner "file" {
    source      = "${path.module}/install_apache.sh"
    destination = "/tmp/install_apache.sh"
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("${path.module}/ssh.pem") # Ruta correcta al archivo ssh.pem
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
      private_key = file("${path.module}/ssh.pem")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "WebServer"
  }

  root_block_device {
    volume_size = var.environment == "prod" ? 50 : 20
    volume_type = "gp2"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg_${var.unique_suffix}"  # Usa el sufijo único
  description = "Allow HTTP and SSH traffic"
  vpc_id      = var.vpc_id

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

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}
