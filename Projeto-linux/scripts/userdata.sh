#!/bin/bash

# Atualizar o sistema
sudo yum update -y

# Instalar o Docker
sudo yum install -y docker

# Adicionar o usuário "ec2-user" ao grupo "docker" para permitir o uso do Docker sem sudo
sudo usermod -a -G docker ec2-user

# Ativar e iniciar o serviço Docker
sudo systemctl enable docker.service
sudo systemctl start docker.service

# Iniciar o Nginx dentro de um container Docker
sudo docker run -d --name nginx-container -p 80:80 nginx

# Exibir o status do container Nginx
sudo docker ps