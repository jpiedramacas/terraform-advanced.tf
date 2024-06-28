
# Práctica Avanzada de Terraform 2

## Sección 1: Creación de Recursos en AWS utilizando Funciones Avanzadas

En esta práctica, vamos a utilizar Terraform para crear varios recursos en AWS y aplicar diversas funciones avanzadas de Terraform para manipular datos y configurar nuestros recursos.

### Paso 1: Configuración Inicial

#### 1.1 Instalación de Terraform

Asegúrate de tener Terraform instalado. Puedes seguir las instrucciones oficiales en la [documentación de Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

### Paso 2: Creación del Proyecto Terraform

#### 2.1 Estructura del Proyecto

Crea un directorio para tu proyecto de Terraform:

```bash
mkdir terraform-aws-practice
cd terraform-aws-practice
```

Dentro de este directorio, crea un archivo `main.tf` donde definiremos nuestros recursos.

### Paso 3: Definición de Variables y Backend

#### 3.1 Definir Variables

Crea un archivo `variables.tf` para definir las variables que utilizaremos:

```hcl
provider "aws" {
  region = "us-east-1" # Cambia esto a tu región preferida
}

variable "prefix" {
  description = "El prefijo para los nombres de los recursos"
  type        = string
  default     = "devops"
}

variable "vpc_cidr" {
  description = "El rango CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

### Paso 4: Crear Recursos Utilizando Funciones Avanzadas

#### 4.1 Función Numérica - `min`

Utilizaremos la función `min` para determinar el número mínimo de subnets a crear:

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

locals {
  subnet_count = min(2, 3, 4)
}

resource "aws_subnet" "subnets" {
  count = local.subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "${var.prefix}-subnet-${count.index}"
  }
}
```

#### 4.2 Función de Cadena - `join`

Utilizaremos la función `join` para crear un nombre concatenado para nuestros recursos:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = join(", ", aws_subnet.subnets.*.id)
}
```

#### 4.3 Función de Fecha y Hora - `formatdate`

Usaremos `formatdate` para crear una etiqueta con la fecha y hora actual en un formato específico:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-01b799c439fd5516a"
  instance_type = "t2.micro"

  tags = {
    Name      = "${var.prefix}-instance"
    CreatedAt = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  }
}
```

#### 4.4 Función de Red IP - `cidrsubnet`

Utilizaremos `cidrsubnet` para calcular subnets adicionales dentro de nuestra VPC:

```hcl
resource "aws_subnet" "additional_subnets" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index + 3)

  tags = {
    Name = "${var.prefix}-additional-subnet-${count.index}"
  }
}
```

### Paso 5: Implementación y Verificación

#### 5.1 Inicializar el Proyecto

Inicializa tu proyecto de Terraform:

```bash
terraform init
```

#### 5.2 Planificar la Infraestructura

Crea un plan para tu infraestructura:

```bash
terraform plan
```

#### 5.3 Aplicar la Configuración

Aplica la configuración para crear los recursos en AWS:

```bash
terraform apply
```

---

Este README proporciona una guía detallada sobre cómo utilizar Terraform para crear recursos en AWS, haciendo uso de funciones avanzadas para la manipulación de datos y configuración de recursos. Asegúrate de ajustar las configuraciones y variables según tus necesidades específicas antes de aplicar la configuración en tu entorno AWS.
