output "web_instance_id" {
  value = aws_instance.web.id
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}
