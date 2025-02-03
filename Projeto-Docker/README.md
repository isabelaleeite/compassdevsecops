# Índice

- [Descrição](#descrição)
- [Arquitetura](#arquitetura)
- [Parte 1: Configuração da VPC](#parte-1-configuração-da-vpc)
- [Parte 2: Configuração de Security Groups](#parte-2-configuração-de-security-groups)
- [Parte 3: Configuração do SSM](#parte-3-configuração-do-ssm)
- [Parte 4: Criação do Banco de Dados no RDS](#parte-4-criação-do-banco-de-dados-no-rds)
- [Parte 5: Configuração do EFS](#parte-5-configuração-do-efs)
- [Parte 6: Configuração do Template de Instância EC2](#parte-6-configuração-do-template-de-instância-ec2)
- [Parte 7: Configuração do Elastic Load Balancer](#parte-7-configuração-do-elastic-load-balancer)
- [Parte 8: Configuração do Auto Scaling Group](#parte-8-configuração-do-auto-scaling-group)
- [Parte 9: Testes](#parte-9-testes)

## **Descrição**

Este projeto tem como objetivo criar uma infraestrutura escalável e altamente disponível para uma aplicação WordPress na AWS. A arquitetura inclui instâncias EC2 configuradas com Docker, um banco de dados MySQL no RDS, o uso do EFS para armazenar arquivos estáticos e a implementação de um Load Balancer e Auto Scaling Group para garantir a alta disponibilidade e escalabilidade. Toda a configuração será realizada por meio da AWS, com a documentação detalhando o processo de configuração e implementação.

## **Arquitetura**

![](img/arquitetura-aws.png)

## Parte 1: Configuração da VPC

### 1.1 Criar a VPC
1. Acesse o Console de Gerenciamento da AWS.
2. No painel de navegação à esquerda, clique em **VPC**.
3. Clique em **Your VPCs** e depois em **Create VPC**.
4. Selecione a opção **VPC and more**.
5. Preencha as configurações:
   - **Name tag**: `wp-docker`
   - **IPv4 CIDR block**: `10.0.0.0/16`
   - **Número de zonas disponíveis**: 2
   - **Número de sub-redes públicas**: 2
   - **Número de sub-redes privadas**: 2
   - **NAT gateways**: **None** (Vamos criar manualmente o NAT Gateway posteriormente).
6. Clique em **Create VPC**.

### 1.2 Criar o NAT Gateway
1. No painel de navegação à esquerda, clique em **NAT Gateways**.
2. Clique em **Create NAT Gateway**.
3. Preencha as configurações:
   - **Nome**: `wp-natgateway`
   - **Sub-rede pública**: Escolha uma das sub-redes públicas criadas pela sua VPC (por exemplo, `sub-rede-publica-1`).
   - **Elastic IP**: Clique em **Allocate Elastic IP** para alocar um IP elástico e associá-lo ao NAT Gateway.
4. Clique em **Create NAT Gateway**.
5. Aguarde até que o estado do seu NAT Gateway fique como **Available** antes de prosseguir.

### 1.3 Associar o NAT Gateway nas Tabelas de Roteamento
1. No painel de navegação à esquerda, clique em **Route Tables**.
2. Identifique as duas tabelas de roteamento associadas às sub-redes privadas criadas pela sua VPC.
   - **Tabela de roteamento para a sub-rede privada 1**.
   - **Tabela de roteamento para a sub-rede privada 2**.
3. Para cada tabela de roteamento, clique no **ID** da tabela e depois em **Edit routes**.
4. Adicione a seguinte rota:
   - **Destination**: `0.0.0.0/0`
   - **Target**: Selecione **NAT Gateway** e escolha o ID do NAT Gateway que você criou (por exemplo, `wp-natgateway`).
5. Clique em **Save routes**.

![](vpc.png)

### 1.4 Concluir a Configuração
Agora que a VPC foi criada com suas sub-redes públicas e privadas, o NAT Gateway está configurado e as rotas foram associadas corretamente, a infraestrutura básica está pronta para continuar com a configuração de outros recursos, como instâncias EC2, RDS e EFS.

## Parte 2: Configuração dos Security Groups

### 2.1 Security Group - **ApplicationLoadBalancer-SG**
1. Navegue até **EC2** e clique em **Security Groups**.
2. Clique em **Create Security Group**.
3. Preencha as configurações:
   - **Nome**: `ApplicationLoadBalancer-SG`
   - **VPC**: Selecione a VPC criada anteriormente (ex: `wp-docker`).
4. **Inbound rules**:
   - **HTTP**: `Port 80`, **Source**: `0.0.0.0/0`
   - **HTTPS**: `Port 443`, **Source**: `0.0.0.0/0`
5. **Outbound rules**:
   - **All traffic**: `Port All`, **Destination**: `0.0.0.0/0`
6. Clique em **Create**.

### 2.2 Security Group - **ApplicationServer-SG**
1. Clique em **Create Security Group**.
2. Preencha as configurações:
   - **Nome**: `ApplicationServer-SG`
   - **VPC**: Selecione a mesma VPC (`wp-docker`).
3. **Inbound rules**:
   - **HTTP**: `Port 80`, **Source**: Selecione **Custom** e escolha o Security Group `ApplicationLoadBalancer-SG`.
   - **HTTPS**: `Port 443`, **Source**: Selecione **Custom** e escolha o Security Group `ApplicationLoadBalancer-SG`.
4. **Outbound rules**:
   - **All traffic**: `Port All`, **Destination**: `0.0.0.0/0`
5. Clique em **Create**.

### 2.3 Security Group - **Database-SG**
1. Clique em **Create Security Group**.
2. Preencha as configurações:
   - **Nome**: `Database-SG`
   - **VPC**: Selecione a mesma VPC (`wp-docker`).
3. **Inbound rules**:
   - **MySQL/Aurora**: `Port 3306`, **Source**: Selecione **Custom** e escolha o Security Group `ApplicationServer-SG`.
4. **Outbound rules**:
   - **MySQL/Aurora**: `Port 3306`, **Destination**: `0.0.0.0/0`
5. Clique em **Create**.

### 2.4 Security Group - **EFS-SG**
1. Clique em **Create Security Group**.
2. Preencha as configurações:
   - **Nome**: `EFS-SG`
   - **VPC**: Selecione a mesma VPC (`wp-docker`).
3. **Inbound rules**:
   - **NFS**: `Port 2049`, **Source**: Selecione **Custom** e escolha o Security Group `ApplicationServer-SG`.
4. **Outbound rules**:
   - **All traffic**: `Port All`, **Destination**: `0.0.0.0/0`
5. Clique em **Create**.

Agora, os **Security Groups** estarão configurados e prontos para uso com as instâncias EC2, Load Balancer, EFS e RDS.

## Parte 3: Configuração do SSM

### Criar Função IAM para o SSM
1. Navegue até **IAM** no Console de Gerenciamento da AWS.
2. No menu à esquerda, clique em **Roles** e depois em **Create role**.
3. Selecione **AWS service** como tipo de entidade confiável.
4. Escolha **EC2** como o serviço que usará a role.
5. Na lista de permissões, selecione **AmazonEC2RoleforSSM** para permitir que a instância EC2 utilize o Systems Manager.
6. Clique em **Next: Tags**. (Você pode adicionar tags se necessário, mas isso é opcional).
7. Clique em **Next: Review**.
8. Dê um nome à função, como `EC2-SSM-Role`.
9. Clique em **Create role** para criar a função.

## Parte 4: Criação do Banco de Dados no RDS

### 4.1 Criar Banco de Dados RDS
1. Navegue até o **RDS** no Console de Gerenciamento da AWS.
2. Na barra lateral esquerda, clique em **Databases** e depois em **Create database**.
3. Escolha a opção **Standard Create**.
4. Selecione **MySQL** como o banco de dados.
5. Escolha a versão **MySQL 8.4.3** (compatível com o WordPress).
6. Selecione o template **Free tier**.
7. Preencha as configurações:
   - **DB instance identifier**: Escolha um nome para o banco de dados (por exemplo, `wordpressdb`).
   - **Master username**: Escolha um nome de usuário para o banco de dados (ex: `admin`).
   - **Master password**: Clique em **Generate password** ou insira uma senha manualmente.
8. **Instance configuration**:
   - **DB instance class**: Selecione `db.t3.micro` (Nível gratuito).
   - **Storage type**: Selecione **SSD gp3** (mais novo e mais barato).
   - **Allocated storage**: Defina para **20 GB**.
   - **Enable autoscaling**: Defina um limite de **50 GB**.
9. **Connectivity**:
   - **VPC**: Selecione a VPC criada anteriormente (`wp-docker`).
   - **Subnet group**: Selecione a **subnetdb-group** criada para o banco de dados.
   - **Public access**: Defina como **No** (não permitir acesso público).
   - **VPC security group**: Selecione **Database-SG**.
10. **Additional configuration**:
    - **DB name**: Insira o nome para o banco de dados, como `wordpressdb`.
    - **Backup**: Desmarque a opção **Enable backups** (para desabilitar o backup automático).
11. Clique em **Create database** e aguarde a criação do banco de dados.

Agora o banco de dados RDS está configurado, com o MySQL 8.4.3, e pronto para ser utilizado pela aplicação WordPress.

## Parte 5: Configuração do EFS

### 5.1 Criar File System EFS
1. Navegue até **EFS** no Console de Gerenciamento da AWS.
2. Clique em **Create file system**.
3. Selecione a opção **Customize** para personalizar as configurações.
4. Preencha as configurações:
   - **Name**: Insira o nome do sistema de arquivos, como `wordpress-efs`.
   - **Storage class**: Deixe como **Regional**.
   - **Backup**: Desmarque a opção **Enable backups** (para desabilitar o backup automático).
5. **Network**:
   - **VPC**: Selecione a **VPC** que você criou anteriormente (`wp-docker`).
6. **Mount targets**:
   - Em **Availability Zones**, selecione a **subnet privada** de cada zona de disponibilidade para garantir que o EFS esteja disponível apenas na sub-rede privada.
   - Em **Security groups**, remova o grupo de segurança padrão e insira o grupo de segurança **SG-EFS** que você criou anteriormente.
   ![](img/efs.png)
7. Clique em **Create** para criar o EFS.

### 5.2 Obter o DNS do EFS
1. Após a criação, clique no **ID** do sistema de arquivos para acessar as informações detalhadas.
2. Na página de detalhes do EFS, copie o **DNS name** do EFS para usar na configuração das instâncias EC2.
   
Agora o sistema de arquivos EFS está configurado e pronto para ser montado nas instâncias EC2.

## Parte 6: Configuração do Template de Instância EC2

### 6.1 Criar Template de Lançamento para Instância EC2
1. Navegue até **EC2** no Console de Gerenciamento da AWS.
2. No menu à esquerda, clique em **Launch Templates** e depois em **Create launch template**.
3. Preencha as configurações conforme abaixo:
   - **Template name**: Insira o nome do template, como `wordpress-temp`.
   - **Template version**: Defina como **v1**.
   - **Auto Scaling guidance**: Deixe como **OK**.
   - **AMI**: Selecione **Amazon Linux 2** (ou a versão do Amazon Linux que você deseja usar).
   - **Instance type**: Escolha o tipo de instância adequado, como `t2.micro` para o nível gratuito.
   
4. **Network settings**:
   - Selecione a VPC criada anteriormente.
   - Marque a opção **Do not include in launch template**  Isso será configurado posteriormente no Auto Scaling Group.

5. **Security Group**:
   - Selecione o **Security Group** criado para o servidor de aplicação, `applicationServer-SG`.

6. **Advanced details**:
   - **IAM Instance Profile**: Selecione o perfil IAM da instância que foi configurado anteriormente (por exemplo, `EC2-SSM-Role`).
   - **User data**: No campo **User data**, insira o script necessário para instalar o **Docker**, **Docker Compose**, e configurar os contêineres para **WordPress** e **MySQL** utilizando o **Docker Compose**.

     ```bash
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
        echo "-insira-o-endereço-efs:/ /mnt/efs nfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
        sudo mount -a

        # Criar o arquivo docker-compose.yaml com os volumes corretos
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
            WORDPRESS_DB_HOST: "insira-o-host-do-RDS"
            WORDPRESS_DB_USER: "insira-user"
            WORDPRESS_DB_PASSWORD: "insira-senha"
            WORDPRESS_DB_NAME: "wordpressdb"
        EOL

        # Inicializar o container do WordPress com Docker Compose
        sudo -u ec2-user docker-compose -f /home/ec2-user/docker-compose.yaml up -d

        echo "Instalação concluída! WordPress está rodando e conectado ao RDS."

     ```
**Observação**: Substitua o endereço EFS pelo o seu, e inserir suas informações no Banco de Dados.

7. Clique em **Create launch template** para criar o template de lançamento.

Agora temos o template de lançamento EC2 configurado com o Amazon Linux 2, as configurações de rede e segurança adequadas, e com o IAM e agentes do Systems Manager configurados no **User data**.

## Parte 7: Configuração do Elastic Load Balancer

### 7.1 Criar o Target Group
1. Vá para o **EC2** no Console de Gerenciamento da AWS.
2. No menu à esquerda, em **Target Groups**, clique em **Create target group**.
3. Preencha os campos da seguinte forma:
   - **Target group name**: `wordpress-tg`
   - **Target type**: **Instances**
   - **Protocol**: **HTTP**
   - **Port**: **80**
   - **VPC**: Selecione a VPC que você criou anteriormente.
4. Clique em **Create** para criar o grupo de destino.

### 7.2 Criar o Load Balancer
1. Vá para **Load Balancers** no Console de Gerenciamento da AWS.
2. Clique em **Create Load Balancer** e selecione **Application Load Balancer**.
3. Preencha as configurações conforme abaixo:
   - **Name**: `wordpress-lb`
   - **Scheme**: **Internet-facing**
   - **IP address type**: **IPv4**
   - **VPC**: Selecione a VPC que você criou anteriormente.
   - **Availability Zones**: Selecione as duas zonas de disponibilidade e suas sub-redes públicas.
   - **Security Groups**: Selecione o **Security Group** `ApplicationLoadBalancer-SG`.
4. Em **Listeners and routing**, selecione o grupo de destino **wordpress-tg** que você criou anteriormente.
5. Clique em **Create load balancer** para finalizar a criação do Load Balancer.

## Parte 8: Configuração do Auto Scaling Group

### 8 Criar e Configurar o Auto Scaling Group
1. No menu à esquerda, vá em **Auto Scaling Groups** e clique em **Create Auto Scaling group**.
2. Preencha as configurações conforme abaixo:
   - **Auto Scaling group name**: `wordpress-asg`
   - **Launch template**: Escolha o **Launch template** que você criou anteriormente (`wordpress-temp`).
   - **VPC**: Selecione a VPC que você criou.
   - **Availability Zones**: Selecione as **zonas privadas** da sua VPC.
   - **Attach to an existing load balancer**: Marque essa opção e selecione o **Load Balancer** `wordpress-lb` e o grupo de destino `wordpress-tg`.
   - **Health checks**: Ative a opção **Elastic Load Balancing health checks**.
   - **Desired capacity**: 2
   - **Minimum capacity**: 1
   - **Maximum capacity**: 2
3. Clique em **Next** para configurar as notificações, se necessário.
4. Configure as notificações por email, caso desejado.
5. Clique em **Create Auto Scaling group** para finalizar a criação do Auto Scaling Group.

## Parte 9: Testes

### 9.1 Verificar o estado do Load Balancer
1. Aguarde as instâncias EC2 serem inicializadas e o Auto Scaling Group realizar a distribuição das instâncias.
2. Vá até o **Load Balancer** no Console de EC2 e verifique se o estado do Load Balancer está como **Active**.
3. Certifique-se de que o status de saúde das instâncias no **Target Group** também esteja saudável (Healthy).

### 9.2 Acessar a aplicação pelo Load Balancer
1. Copie o **DNS name** do **Load Balancer** gerado.
2. Abra o seu navegador e cole o **DNS name** do Load Balancer na barra de endereços.
3. Se tudo estiver configurado corretamente, você deverá ver a página inicial do **WordPress**.

### 9.3 Configurar o WordPress
1. Ao acessar o WordPress pela primeira vez, será solicitado que você configure uma conta de login.
2. Siga o assistente de instalação do WordPress para configurar o banco de dados, escolher o idioma e definir as credenciais de administrador.
3. Após a configuração, você poderá acessar o painel administrativo do WordPress para gerenciar sua aplicação.

Pronto! A aplicação WordPress está configurada, escalável e funcionando corretamente.

