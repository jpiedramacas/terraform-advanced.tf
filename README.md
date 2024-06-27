# Práctica Avanzada de Terraform

## Introducción

En esta práctica avanzada, aprenderás a usar los provisioners `file` y `remote-exec` en Terraform para añadir y ejecutar scripts en una instancia de EC2 en AWS. Configurarás un servidor web como ejemplo práctico.

## Sección 1: Instalación y Uso de los Provisioners `file` y `remote-exec`

### Requisitos Previos

1. Tener una cuenta de AWS.
2. Instalar Terraform en tu máquina local.
3. Configurar AWS CLI con tus credenciales de AWS.

### Paso 1: Crear un Archivo de Configuración de Terraform

Crea un directorio para tu proyecto de Terraform y dentro de él un archivo llamado `main.tf`.

```bash
mkdir terraform-ec2
cd terraform-ec2
touch main.tf
```

### Paso 2: Configurar el Proveedor de AWS

En el archivo `main.tf`, añade la configuración del proveedor de AWS.

```hcl
provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}
```

### Paso 3: Crear una Instancia de EC2

Añade la configuración para crear una instancia de EC2. Asegúrate de que tienes un par de claves SSH creado en AWS para acceder a la instancia.

```hcl
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
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_apache.sh",
      "sudo /tmp/install_apache.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("ssh.pem") # Ruta a tu clave privada
    host        = self.public_ip
  }
}
```

### Paso 4: Crear el Security Group

Añade la configuración para crear un Security Group que permita tráfico HTTP y SSH.

```hcl
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
```

### Paso 5: Crear el Script de Instalación de Apache

Crea un archivo llamado `install_apache.sh` en el mismo directorio.

```bash
touch install_apache.sh
```

Añade el siguiente contenido al archivo `install_apache.sh` para instalar y configurar Apache.

```bash
#!/bin/bash
# Actualiza los paquetes e instala Apache
sudo yum update -y
sudo yum install -y httpd

# Inicia Apache y habilita para que inicie en cada reinicio del sistema
sudo systemctl start httpd
sudo systemctl enable httpd

# Crea una página web de ejemplo
echo "<html><h1>Hola desde Terraform!</h1></html>" | sudo tee /var/www/html/index.html
```

### Paso 6: Obtener la Clave SSH Privada

Obten la clave SSH privada del laboratorio y pega el contenido en un archivo llamado `ssh.pem` en la ruta raíz del proyecto de Terraform.

### Paso 7: Inicializar y Aplicar la Configuración de Terraform

Inicializa tu proyecto de Terraform y aplica la configuración.

```bash
terraform init
terraform apply
```

Confirma la aplicación cuando se te solicite (escribe `yes` y presiona Enter).

### Verificación

Una vez que la aplicación se complete, obtendrás la dirección IP pública de la instancia de EC2. Puedes verificar que Apache está instalado y funcionando accediendo a esta dirección IP en tu navegador. Para obtener la IP pública automáticamente, añade un output en Terraform:

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

## Sección 2: Creación de un VPC con Subredes Condicionales

### Paso 1: Añadir el Recurso VPC

Añade la configuración para crear un VPC.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

### Paso 2: Añadir Subredes Utilizando Expresiones Condicionales

Define una variable de entorno y configura subredes condicionalmente.

```hcl
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
```

### Paso 3: Aplicación de Operadores y Llamadas a Funciones

Crea un recurso de grupo de seguridad con reglas basadas en operadores.

```hcl
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
```

Usa funciones y operadores en las configuraciones.

```hcl
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
```

### Paso 4: Uso de Expresiones For y Splat

Crea una lista de nombres de subredes utilizando `for`.

```hcl
locals {
  subnet_names = [for i in aws_subnet.subnet : "subnet-${i.availability_zone}"]
}

output "subnet_names" {
  value = local.subnet_names
}
```

Utiliza splat para obtener los IDs de las subredes.

```hcl
output "subnet_ids" {
  value = aws_subnet.subnet[*].id
}
```

### Paso 5: Ejecución de la Configuración de Terraform

Inicializa Terraform.

```bash
terraform init
```

Revisa el plan de ejecución.

```bash
terraform plan
```

Aplica el plan.

```bash
terraform apply
```
