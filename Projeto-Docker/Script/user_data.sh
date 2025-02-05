#!/bin/bash

# Atualizar pacotes e instalar dependências
sudo yum update -y
sudo yum install -y docker nfs-utils

# Instalar o SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Habilitar e iniciar o Docker
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar ec2-user ao grupo docker
sudo usermod -aG docker ec2-user

# Instalar Docker Compose
sudo curl -SL https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Montar EFS
EFS_DNS="seu-caminho-efs"  # DNS do EFS diretamente
EFS_PATH="/mnt/efs/wordpress"  # Caminho do diretório EFS

# Criar diretório EFS e montar
sudo mkdir -p $EFS_PATH
sudo chmod -R 777 $EFS_PATH
echo "$EFS_DNS:/ $EFS_PATH nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Definir as variáveis de ambiente para o WordPress
WORDPRESS_DB_HOST="seu-endpoint-rds"
WORDPRESS_DB_USER="seu-usuario"
WORDPRESS_DB_PASSWORD="sua-senha"
WORDPRESS_DB_NAME="wordpressdb"

# Criar o arquivo docker-compose.yaml com as variáveis de ambiente
cat <<EOL > /home/ec2-user/docker-compose.yaml

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    volumes:
      - $EFS_PATH:/var/www/html  # Monta os arquivos do WordPress no EFS
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: "$WORDPRESS_DB_HOST"
      WORDPRESS_DB_USER: "$WORDPRESS_DB_USER"
      WORDPRESS_DB_PASSWORD: "$WORDPRESS_DB_PASSWORD"
      WORDPRESS_DB_NAME: "$WORDPRESS_DB_NAME"
EOL

# Inicializar o container do WordPress com Docker Compose
sudo -u ec2-user bash -c "cd /home/ec2-user && docker-compose -f docker-compose.yaml up -d"

echo "Instalação concluída! WordPress está rodando e conectado ao RDS."
