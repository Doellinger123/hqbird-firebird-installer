#!/bin/bash

echo "==== Atualizando o sistema e instalando dependências ===="
sudo apt update && sudo apt upgrade -y
sudo apt install curl wget nano ufw lsof net-tools unzip openjdk-8-jdk -y

echo "==== Removendo Firebird antigo, se existir ===="
sudo systemctl stop firebird* || true
sudo apt remove --purge firebird* -y
sudo rm -rf /opt/fb50 /var/lib/firebird /etc/firebird /var/log/firebird
sudo systemctl daemon-reload

echo "==== Baixando e preparando instalador do HQBird Firebird 5 ===="
wget https://cc.ib-aid.com/download/distr/install.sh -O install_fb.sh
chmod +x install_fb.sh

echo "==== Instalando Firebird 5 ===="
sudo ./install_fb.sh --fb50 --fb50-path=/opt/fb50 --fb50-port=3050

echo "==== Criando pastas do banco de dados ===="
sudo mkdir -p /opt/fb50/database
sudo chown firebird:firebird /opt/fb50/database
sudo chmod 777 /opt/fb50/database

echo "==== Copiando banco de dados ===="
sudo cp ./athenas.fdb /opt/fb50/database/
sudo chown firebird:firebird /opt/fb50/database/athenas.fdb
sudo chmod 777 /opt/fb50/database/athenas.fdb

echo "==== Criando e copiando UDFs ===="
sudo mkdir -p /opt/fb50/UDF
sudo cp ./UDF/*.so /opt/fb50/UDF/
sudo chown firebird:firebird /opt/fb50/UDF/*.so
sudo chmod 777 /opt/fb50/UDF/*.so

echo "==== Configurando firebird.conf ===="
sudo sed -i 's/^#*DataTypeCompatibility.*/DataTypeCompatibility = 3.0/' /opt/fb50/etc/firebird.conf
sudo sed -i 's/^#*UDFAccess.*/UDFAccess = Restrict UDF/' /opt/fb50/etc/firebird.conf
sudo sed -i 's/^#*RemoteBindAddress.*/RemoteBindAddress = 0.0.0.0/' /opt/fb50/etc/firebird.conf

echo "==== Desabilitando firewall para não bloquear a porta ===="
sudo ufw disable

echo "==== Ativando e iniciando Firebird ===="
sudo systemctl enable firebird.opt_fb50.service
sudo systemctl restart firebird.opt_fb50.service

echo "==== Testando serviço ===="
sudo systemctl status firebird.opt_fb50.service

echo "==== Testando conexão ao banco ===="
isql -u sysdba -p masterkey localhost/3050:/opt/fb50/database/athenas.fdb <<EOF
select * from rdb\$relations;
commit;
quit;
EOF

echo "==== Instalação finalizada com sucesso! ===="