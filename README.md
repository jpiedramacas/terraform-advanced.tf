# Práctica Avanzada de Terraform 2

## Creación de Recursos en AWS utilizando Funciones Avanzadas

En esta práctica, vamos a crear una serie de recursos en AWS utilizando Terraform. Aplicaremos varias funciones avanzadas de Terraform para manipular datos y configurar nuestros recursos.

Las funciones que utilizaremos son:

- Funciones numéricas (`min`)
- Funciones de cadena (`join`)
- Funciones de fecha y hora (`formatdate`)
- Funciones de red IP (`cidrsubnet`)

## Paso 1: Definición de Variables y Backend

### 1.1. Definir Variables

Para facilitar la gestión y reutilización de valores en nuestro proyecto, utilizaremos variables. Crea un archivo llamado `variables.tf` donde definiremos estas variables.

Abre `variables.tf` y añade las siguientes definiciones:

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

- **`provider "aws"`**: Especifica el proveedor de infraestructura, en este caso AWS, y la región en la que se crearán los recursos.
- **`variable "prefix"`**: Variable para definir un prefijo común que se utilizará en los nombres de los recursos.
- **`variable "vpc_cidr"`**: Variable para definir el rango de direcciones IP (CIDR) para la VPC.

## Paso 2: Crear Recursos Utilizando Funciones Avanzadas

### 2.1. Función Numérica - `min`

La función `min` se utiliza para encontrar el valor mínimo entre los valores dados. En este caso, la utilizaremos para determinar el número mínimo de subnets a crear.

Crea un archivo `main.tf` y añade lo siguiente:

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
  count             = local.subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  tags = {
    Name = "${var.prefix}-subnet-${count.index}"
  }
}
```

- **`resource "aws_vpc" "main"`**: Crea una VPC con el rango de direcciones IP especificado en `var.vpc_cidr`.
- **`locals { subnet_count = min(2, 3, 4) }`**: Define una variable local que contiene el valor mínimo entre 2, 3 y 4.
- **`resource "aws_subnet" "subnets"`**: Crea subnets en la VPC. El número de subnets creadas es determinado por `local.subnet_count`.

### 2.2. Función de Cadena - `join`

La función `join` concatena una lista de cadenas en una sola cadena, separadas por un delimitador especificado. Utilizaremos esta función para crear una salida que contenga una lista de IDs de subnets separadas por comas.

Añade al final de `main.tf`:

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = join(", ", aws_subnet.subnets[*].id)
}
```

- **`output "vpc_id"`**: Muestra el ID de la VPC creada.
- **`output "subnet_ids"`**: Muestra los IDs de las subnets creadas, concatenados en una sola cadena separada por comas.

### 2.3. Función de Fecha y Hora - `formatdate`

La función `formatdate` formatea una marca de tiempo (timestamp) en una cadena de fecha y hora específica. Utilizaremos esta función para etiquetar una instancia con la fecha y hora actuales.

Añade al final de `main.tf`:

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

- **`resource "aws_instance" "web"`**: Crea una instancia EC2 con el AMI y tipo de instancia especificados.
- **`tags`**: Añade etiquetas a la instancia, incluyendo una etiqueta `CreatedAt` con la fecha y hora actuales.

### 2.4. Función de Red IP - `cidrsubnet`

La función `cidrsubnet` calcula subnets adicionales dentro de un bloque CIDR existente. Utilizaremos esta función para crear subnets adicionales en nuestra VPC.

Añade al final de `main.tf`:

```hcl
resource "aws_subnet" "additional_subnets" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index + 3)
  tags = {
    Name = "${var.prefix}-additional-subnet-${count.index}"
  }
}
```

- **`resource "aws_subnet" "additional_subnets"`**: Crea subnets adicionales en la VPC. El rango de direcciones IP de cada subnet se calcula usando `cidrsubnet`.

## Paso 3: Implementación y Verificación

### 3.1. Inicializar el Proyecto

Para inicializar tu proyecto de Terraform y descargar los plugins necesarios, ejecuta:

```sh
terraform init
```

### 3.2. Planificar la Infraestructura

Antes de aplicar la configuración, es una buena práctica crear un plan para revisar los cambios que se harán en tu infraestructura. Ejecuta:

```sh
terraform plan
```

Este comando mostrará un resumen de los recursos que se crearán, actualizarán o eliminarán.

### 3.3. Aplicar la Configuración

Finalmente, aplica la configuración para crear los recursos en AWS:

```sh
terraform apply
```

Terraform te pedirá confirmación antes de aplicar los cambios. Escribe `yes` para confirmar.

