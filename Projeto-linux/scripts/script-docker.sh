#!/bin/bash

# Definindo variáveis de saída para arquivos de log
LOG_ONLINE="/var/log/nginx-logs/status_online.log"
LOG_OFFLINE="/var/log/nginx-logs/status_offline.log"

# Cria o diretório de logs, se não existir
sudo mkdir -p /var/log/nginx-logs
sudo touch $LOG_ONLINE
sudo touch $LOG_OFFLINE
sudo chmod 644 $LOG_ONLINE $LOG_OFFLINE

# Armazena a data e hora atual
DATA=$(date "+%Y-%m-%d %H:%M:%S")

# Nome do container Docker que executa o Nginx
CONTAINER_NAME="nginx-container"

# Verifica o status do container Docker
if sudo docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q $CONTAINER_NAME; then
    echo "$DATA : [Nginx - Online] Container em execução." | sudo tee -a $LOG_ONLINE > /dev/null
    echo "Nginx está online no container."
else
    echo "$DATA : [Nginx - Offline] Container parado." | sudo tee -a $LOG_OFFLINE > /dev/null
    echo "Nginx está offline no container."
fi