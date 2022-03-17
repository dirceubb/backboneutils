### Instalar Vesta

# Download installation script
curl -O http://vestacp.com/pub/vst-install.sh

# Hacerlo ejecutable
sudo chmod +x vst-install.sh

# ejecutar con los siguientes argumentos para que no instale los componentes que no son tan necesarios
sudo ./vst-install.sh --nginx yes --apache yes --phpfpm no --named no --remi yes --vsftpd no --proftpd no --iptables no --fail2ban no --quota no --exim no --dovecot no --spamassassin no --clamav no --softaculous yes --mysql yes --postgresql no

# Si no le pones ningún argumento va a instalar todos los complementos
sudo ./vst-install.sh

# Reiniciar Servidor
sudo reboot
