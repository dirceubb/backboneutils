# Instrucciones para implementar odoo mediante scripts backbone

# Descargar script con wget
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14deploy.sh
# Asignar Permisos de ejecusión al script
chmod u+x odoo14deploy.sh
# Ejecutar script con sudo
sudo ./odoo14deploy.sh

# En este punto ya se tiene a odoo funcionando y se puede proseguir con la creación de la base de datos mediante el acceso web

# Si se requiere una implementación profesional se debe ejecutar el script odoo14nginxdeploy.sh para tener un certificado válido y la aplicación corriendo en modo proxy con buenos ajustes de workers

wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14nginxdeploy.sh
chmod u+x odoo14nginxdeploy.sh
sudo ./odoo14nginxdeploy.sh

# Para agregar dominios protegidos con letsencrypt, ejecutar el siguiente script.
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14nginx-extra-domain.sh
chmod u+x odoo14nginx-extra-domain.sh
sudo ./odoo14nginx-extra-domain.sh