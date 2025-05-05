#!/bin/bash
set -eux

# Evitar prompts interactivos
export DEBIAN_FRONTEND=noninteractive

# Actualizar sistema e instalar dependencias
apt-get update -y
apt-get install -y nginx git stress netcat

# Iniciar y habilitar Nginx
systemctl enable --now nginx

# Directorio raíz de Nginx en Ubuntu
WEB_DIR="/var/www/html"

# Obtener el VM ID desde Azure Instance Metadata Service
INSTANCE_ID=$(curl -s -H "Metadata: true" \
  "http://169.254.169.254/metadata/instance/compute/vmId?api-version=2021-02-01&format=text")

# Limpiar contenido viejo y preparar directorio
rm -rf /tmp/tfg-web
rm -rf ${WEB_DIR:?}/*
mkdir -p $WEB_DIR

# Clonar tu repo y desplegar la web
git clone https://github.com/joquiro85/tfg-html-azure.git /tmp/tfg-web
cp -r /tmp/tfg-web/* $WEB_DIR/

# Inyectar el VM ID en index.html
sed -i "s/\$INSTANCE_ID/$INSTANCE_ID/g" $WEB_DIR/index.html

# Ajustar permisos al usuario de Nginx en Ubuntu
chown -R www-data:www-data $WEB_DIR
chmod -R 755 $WEB_DIR

# Reiniciar Nginx para asegurar configuración limpia
systemctl restart nginx

# Correr stress en background (2 CPUs durante 300s)
# nohup stress --cpu 2 --timeout 300 >/var/log/stress.log 2>&1 &
