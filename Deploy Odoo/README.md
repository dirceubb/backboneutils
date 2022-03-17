# Instrucciones para implementar odoo mediante scripts backbone

# Descargar script con wget dependiendo de la versión de Odoo
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14deploy.sh
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo15deploy.sh
# Asignar Permisos de ejecusión al script
chmod u+x odoo14deploy.sh
chmod u+x odoo15deploy.sh
# Ejecutar script con sudo
sudo ./odoo14deploy.sh
sudo ./odoo15deploy.sh

# En este punto ya se tiene a odoo funcionando y se puede proseguir con la creación de la base de datos mediante el acceso web

# Si se requiere una implementación profesional se debe ejecutar el script odoo14nginxdeploy.sh para tener un certificado válido y la aplicación corriendo en modo proxy con buenos ajustes de workers

wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14nginxdeploy.sh
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo15nginxdeploy.sh
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo15nginxdeploy-sin-www.sh

chmod u+x odoo14nginxdeploy.sh
sudo ./odoo14nginxdeploy.sh

chmod u+x odoo15nginxdeploy.sh
sudo ./odoo15nginxdeploy.sh

# Para agregar dominios protegidos con letsencrypt, ejecutar el siguiente script.
wget https://raw.githubusercontent.com/dirceubb/backboneutils/main/Deploy%20Odoo/odoo14nginx-extra-domain.sh

chmod u+x odoo14nginx-extra-domain.sh

sudo ./odoo14nginx-extra-domain.sh