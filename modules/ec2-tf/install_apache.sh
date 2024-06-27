#!/bin/bash
# Actualiza los paquetes e instala Apache
sudo yum update -y
sudo yum install -y httpd

# Inicia Apache y habilita para que inicie en cada reinicio del sistema
sudo systemctl start httpd
sudo systemctl enable httpd

# Descargar y descomprimir la página web de ejemplo
wget https://www.free-css.com/assets/files/free-css-templates/download/page296/finexo.zip 
sudo yum install -y unzip
sudo unzip finexo.zip 

# Mover los archivos descomprimidos a la carpeta de Apache
sudo mv finexo-html/* /var/www/html/

# Reiniciar Apache
sudo systemctl restart httpd
