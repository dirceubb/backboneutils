#!/bin/bash

# Instalar Odoo 15 en un ambiente virtual de python en Ubuntu 20.04 #
# Este script se basa en la guía de Linuxize "How to Install Odoo 15 on Ubuntu 20.04" en la url https://linuxize.com/post/how-to-install-odoo-15-on-ubuntu-20-04/
# Para debuguear instalación y guardarlo en odoo15deploy.log descomentar la linea de abajo
# exec 3> odoo15deploy.log

# 1.- Prerequisitos del sistema
# Actualizar Linux
sudo apt update && sudo apt -y upgrade
# Instalar dependencias necesarias para odoo y python

sudo apt -y install git python3-pip build-essential wget python3-dev python3-venv \
    python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev \
    python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev \
    libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev
# Crear usuario que correrá Odoo y asignarle la carpeta /opt/odoo15
sudo useradd -m -d /opt/odoo15 -U -r -s /bin/bash odoo15
# Instalar PostgreSQL 
sudo apt -y install postgresql
# Crear usuario de postgresql con el mismo nombre del usuario para odoo en este caso odoo15
sudo su - postgres -c "createuser -s odoo15"
# Instalar wkhtmltopdf, una herramienta para renderizar html hacia PDF y otros formatos de imagen
sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo apt -y install ./wkhtmltox_0.12.6-1.bionic_amd64.deb

# 2.- Instalar Odoo en ambiente virtual de Python
# Clonar el código fuente de Odoo 15 desde Github. (ejecutar como usuario odoo15)
sudo -u odoo15 git clone https://www.github.com/odoo/odoo --depth 1 --branch 15.0 /opt/odoo15/odoo
# Crear un ambiente virtual de Python para Odoo. Será en la misma carpeta del usuario de odoo. (ejecutar como usuario odoo15)
cd /opt/odoo15
sudo -u odoo15 python3 -m venv odoo-venv
# Se debe "encapsular" dentro de una funcion los comandos necesarios para crear el ambiente virutal de python. Esto es por como funcionan los procesos de linux y el comando source
requerimientos_venv () {
        # Activar el ambiente virtual python
        source odoo-venv/bin/activate
        # Instalar los requerimientos de odoo para python con pip3. (ejecutar como usuario odoo15)
        pip3 install wheel
        pip3 install -r odoo/requirements.txt
        # Desactivar el ambiente virtual python
        deactivate
}
requerimientos_venv
# Crear directorio donde se alojarán los módulos de terceros. (ejecutar como usuario odoo15)
sudo -u odoo15 mkdir /opt/odoo15/odoo-custom-addons

# 3.- Configurar "inicialmente" Odoo y crear servicio del mismo
# Crear archivo de configuración
# Nota: en futuras versiones del script es importante que los parámetros del archivo .conf sean interactivos (Principalmente el admin_passwd)
sudo cat << EOT > /etc/odoo15.conf
[options]
; This is the password that allows database operations:
admin_passwd = ChangeMe
db_host = False
db_port = False
db_user = odoo15
db_password = False
addons_path = /opt/odoo15/odoo/addons,/opt/odoo15/odoo-custom-addons

;proxy_mode = True

;limit_memory_hard = 1226078945
;limit_memory_soft = 1021734454
;limit_request = 8192
;limit_time_cpu = 600
;limit_time_real = 1200
;max_cron_threads = 1
;workers = 2

; Filtrar bases de datos por el comienzo de la url y quitar la lista de bases de datos
;dbfilter = ^%h$
;list_db = False
EOT
# Crear archivo de Systemd para crear servicio odoo15
sudo cat << EOT > /etc/systemd/system/odoo15.service
[Unit]
Description=odoo15
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo15
PermissionsStartOnly=true
User=odoo15
Group=odoo15
ExecStart=/opt/odoo15/odoo-venv/bin/python3 /opt/odoo15/odoo/odoo-bin -c /etc/odoo15.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOT
# Avisarle al systemd que existe una nueva unidad
sudo systemctl daemon-reload
# Iniciar servicio de odoo y habilitar que se inicie con el sistema
sudo systemctl enable --now odoo15
# Verificar Estado del servicio. Recomiendo pausa aqui, para que el administrador revise que el servicio esta arriba y que odoo ya esta trabajando
sudo systemctl status odoo15
