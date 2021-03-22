#!/bin/bash

# Clonar el código fuente de Odoo 14 desde Github. (ejecutar como usuario odoo14)
sudo -u odoo14 git clone https://www.github.com/odoo/odoo --depth 1 --branch 14.0 /opt/odoo14/odoo
# Crear un ambiente virtual de Python para Odoo. Será en la misma carpeta del usuario de odoo. (ejecutar como usuario odoo14)
cd /opt/odoo14
sudo -u odoo14 python3 -m venv odoo-venv
# Activar el ambiente virtual python.
source odoo-venv/bin/activate
# Instalar los requerimientos de odoo para python con pip3. (ejecutar como usuario odoo14)
sudo -u odoo14 pip3 install wheel
sudo -u odoo14 pip3 install -r odoo/requirements.txt
# Desactivar el ambiente, tecleando
deactivate
# Crear directorio donde se alojarán los módulos de terceros. (ejecutar como usuario odoo14)
sudo -u odoo14 mkdir /opt/odoo14/odoo-custom-addons