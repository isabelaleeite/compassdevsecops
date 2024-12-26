
#!/bin/bash

# Definindo variáveis de saída para arquivos de log no diretório /var/log/nginx/
LOG_ONLINE="/var/log/nginx/status_online.log"
LOG_OFFLINE="/var/log/nginx/status_offline.log"

# Cria os arquivos de log, se não existirem, com permissões apropriadas
sudo touch $LOG_ONLINE
sudo touch $LOG_OFFLINE
sudo chmod 644 $LOG_ONLINE $LOG_OFFLINE

# Armazena a data e hora atual
DATA=$(date "+%Y-%m-%d %H:%M:%S")

# Variável do nome do serviço
SERVICO="NGINX"

# Verifica o status do serviço e armazena dentro do arquivo de log
if systemctl is-active --quiet nginx; then
    echo "$DATA : [$SERVICO - Online] Servidor em execução." | sudo tee -a $LOG_ONLINE > /dev/null
    echo "NGINX está online"
else
    echo "$DATA : [$SERVICO - Offline] Servidor fora de execução." | sudo tee -a $LOG_OFFLINE > /dev/null
    echo "NGINX está offline"
fi
