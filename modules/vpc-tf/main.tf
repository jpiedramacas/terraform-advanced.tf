resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  count = var.environment == "prod" ? 2 : 1
  vpc_id = aws_vpc.main.id
  cidr_block = var.environment == "prod" ? element(["10.0.1.0/24", "10.0.2.0/24"], count.index) : "10.0.1.0/24"
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = aws_subnet.subnet[*].id
}
