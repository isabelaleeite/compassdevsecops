#!/bin/bash

# Atualizar os pacotes para a última versão
sudo yum update -y

# Instalar o SSM Agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Instalar o Docker
sudo yum install -y docker

# Iniciar o serviço do Docker e habilitar na inicialização
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar o usuário ao grupo docker
sudo usermod -aG docker ec2-user

# Instalar Docker Compose
sudo curl -SL https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Instalar nfs-utils para suportar EFS
sudo yum install -y nfs-utils

# Criar diretórios para o EFS
sudo mkdir -p /mnt/efs/wordpress

# Alterar permissões para garantir acesso ao EFS
sudo chmod -R 777 /mnt/efs

# Montar o EFS automaticamente
echo "fs-0c704a1d40eb3c9ef.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Criar o arquivo docker-compose.yaml com as variáveis de ambiente
cat <<EOL > /home/ec2-user/docker-compose.yaml
version: '3.8'

services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    volumes:
      - /mnt/efs/wordpress:/var/www/html  # Monta os arquivos do WordPress no EFS
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: "\${WORDPRESS_DB_HOST}"
      WORDPRESS_DB_USER: "\${WORDPRESS_DB_USER}"
      WORDPRESS_DB_PASSWORD: "\${WORDPRESS_DB_PASSWORD}"
      WORDPRESS_DB_NAME: "\${WORDPRESS_DB_NAME}"
EOL

# Criar um arquivo de variáveis de ambiente para o Docker Compose
cat <<EOL > /home/ec2-user/.env
WORDPRESS_DB_HOST="database-01.c50ic0a6of2e.us-east-1.rds.amazonaws.com"
WORDPRESS_DB_USER="admin"
WORDPRESS_DB_PASSWORD="sua_senha_secreta"
WORDPRESS_DB_NAME="wordpressdb"
EOL

# Inicializar o container do WordPress com Docker Compose, carregando as variáveis
sudo -u ec2-user bash -c "cd /home/ec2-user && docker-compose --env-file .env -f docker-compose.yaml up -d"

echo "Instalação concluída! WordPress está rodando e conectado ao RDS."
