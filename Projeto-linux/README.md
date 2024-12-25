# Projeto: Monitoramento Nginx - Compass UOL | Atividade Prática 1 #PB - NOV 2024 | DevSecOps

## **Descrição**
Este projeto cria um ambiente Linux no Windows usando o WSL, configura um servidor Nginx rodando em uma instância EC2 da AWS, e implementa um script para monitorar o status do serviço Nginx, gerando logs automatizados.

---

# Índice

- [Descrição](#descrição)
- [Parte 1: Instalação do WSL no Windows](#parte-1-instalação-do-wsl-no-windows)
  - [Ativar o Subsistema do Windows para Linux](#1-ativar-o-subsistema-do-windows-para-linux)
  - [Instalar o WSL](#2-instalar-o-wsl)
  - [Instalar o Ubuntu pela Microsoft Store](#3-instalar-o-ubuntu-pela-microsoft-store)
- [Parte 2: Configurar ambiente AWS](#parte-2-configurar-ambiente-aws)
  - [Criar a VPC](#1-criar-a-vpc)
  - [Configurar os parâmetros da VPC](#2-configurar-os-parâmetros-da-vpc)
  - [Finalizar a criação](#3-finalizar-a-criação)
  - [Criar o Grupo de Segurança](#4-criar-o-grupo-de-segurança)
  - [Criar Instância EC2](#5-criar-instância-ec2)
  - [Conectar à Instância EC2 via SSH](#6-conectar-à-instância-ec2-via-ssh)
- [Parte 3: Instalando e configurando o Nginx](#parte-3-instalando-e-configurando-o-nginx)
  - [Atualização do Sistema Ubuntu](#1-atualização-do-sistema-ubuntu)
  - [Instalando o Nginx](#2-instalando-o-nginx)
  - [Verificando o Status do Nginx](#3-verificando-o-status-do-nginx)
  - [Habilitar o Nginx para iniciar automaticamente](#4-habilitar-o-nginx-para-iniciar-automaticamente)
  - [Acessando o Nginx](#5-acessando-o-nginx)
- [Parte 4: Criação do Script de Verificação](#parte-4-criação-do-script-de-verificação)
  - [Acessando o diretório de logs do Nginx e alterando permissões](#1-acessando-o-diretório-de-logs-do-nginx-e-alterando-permissões)
  - [Criando o diretório para armazenar o Script](#2-criando-o-diretório-para-armazenar-o-script)
  - [Criando o Script de verificação](#3-criando-o-script-de-verificação)
  - [Inserindo o código no arquivo](#4-inserindo-o-código-no-arquivo)
  - [Deixando o script executável](#5-deixando-o-script-executável)
- [Parte 5: Automatizando o Script](#parte-5-automatizando-o-script)
  - [Editando o arquivo de tarefas agendadas do cron](#1-editando-o-arquivo-de-tarefas-agendadas-do-cron)
  - [Adicionando a linha no cron para execução a cada 5 minutos](#2-adicionando-a-linha-no-cron-para-execução-a-cada-5-minutos)
  - [Salvando e saindo do editor](#3-salvando-e-saindo-do-editor)
- [Parte 6: Testando](#parte-6-testando)
  - [Verificando os arquivos de log](#1-verificando-os-arquivos-de-log)

---

## **Parte 1: Instalação do WSL no Windows**

### **1. Ativar o Subsistema do Windows para Linux**
1. Abra o **Painel de Controle**.
2. Acesse **Programas** > **Programas e Recursos** > **Ativar ou desativar recursos do Windows**.
3. Habilite a opção **Subsistema do Windows para Linux**.
4. Clique em **OK** e reinicie o computador para aplicar as alterações.

### **2. Instalar o WSL**
1. Abra o **PowerShell** como administrador:
   - Clique no botão **Iniciar**, digite **PowerShell**, clique com o botão direito e selecione **Executar como administrador**.
2. Execute o comando abaixo para instalar o WSL:
   ```powershell
   wsl --install

### **3. Instalar o Ubuntu pela Microsoft Store**
1. Abra a **Microsoft Store**:
2. Pesquise por **Ubuntu** e selecione a versão desejada (**Ubuntu 20.04** ou superior é recomendado).
3. Clique em **Instalar** para adicionar a distribuição ao seu sistema.

---

## **Parte 2: Configurar ambiente AWS**

### **1. Criar a VPC**
1. Faça login na sua conta AWS.
2. No painel principal, vá até **Serviços** e selecione **VPC**.
3. Clique no botão **Criar VPC**.
4. Na próxima tela, selecione a opção **VPC e muito mais**.

### **2. Configurar os parâmetros da VPC**
Preencha os campos conforme indicado abaixo:

- **Nome da VPC**: Insira um nome descritivo, como `minha-vpc`.
- **Número de zonas de disponibilidade**: **2** (mantenha o padrão).
- **Número de sub-redes públicas**: **2**.
- **Número de sub-redes privadas**: **0**. (nesse projeto não utilizaremos sub-redes privadas)
- **NAT Gateways**: **Nenhum**.
- **Endpoints da VPC**: **Nenhum**.

### **3. Finalizar a criação**
1. Revise as configurações para garantir que estão corretas.
2. Clique no botão **Criar VPC**.
3. Aguarde o processo de criação ser concluído.

### Explicações

- **VPC**: Uma VPC é uma rede virtual isolada dentro da AWS, onde você pode executar recursos, como instâncias EC2, de forma segura. Criar uma VPC permite que você tenha controle sobre o tráfego de rede e defina a arquitetura de rede de acordo com as necessidades do seu projeto.
- **Zonas de Disponibilidade (AZs)**: As zonas de disponibilidade são locais fisicamente separados dentro de uma região. Ao distribuir seus recursos em múltiplas AZs, você aumenta a resiliência e a disponibilidade do seu ambiente. 
- **Subnets Públicas**: As subnets públicas são aquelas que têm acesso direto à Internet, essencial para a execução de servidores web, como o Nginx, ou outros serviços que precisam se comunicar com a Internet.
- **NAT Gateway**: O NAT Gateway permite que instâncias em subnets privadas acessem a Internet. No entanto, como não utilizaremos subnets privadas neste projeto, não será necessário configurar um NAT Gateway.
- **Endpoints da VPC**: Endpoints permitem que você se conecte a serviços da AWS de forma privada dentro da sua VPC, sem precisar passar pela Internet. No entanto, neste projeto, não há necessidade de configurar endpoints da VPC.

### 4. Criar o Grupo de Segurança

1. **Acesse o Console de EC2** e vá para **Security Groups**.
2. **Crie um novo grupo**:
   - **Nome**: Dê um nome para o seu grupo de segurança
   - **Descrição**: `Grupo de segurança para controlar tráfego da EC2`
   - **Vincule à VPC** criada.
3. **Adicionar Regras de Entrada**:
   - **SSH (porta 22)**: 
     - Fonte: `0.0.0.0/0` (acesso SSH de qualquer IP)
   - **HTTP (porta 80)**: 
     - Fonte: `0.0.0.0/0` (acesso HTTP público)
4. **Adicionar Regras de Saída**:
   - **Todo o tráfego**: 
     - Destino: `0.0.0.0/0` (permite tráfego de saída irrestrito)
5. **Revisar e Criar**.

### Explicações

- **SSH**: Liberar `0.0.0.0/0` é necessário para acessar a instância, mas recomenda-se restringir a um IP específico por segurança.
- **HTTP**: Liberar o tráfego HTTP de `0.0.0.0/0` permite acesso público ao servidor Nginx.
- **Saída**: Permitir todo tráfego de saída facilita a comunicação da instância com a internet, mas pode ser restrito conforme a necessidade de segurança.

Esse processo garante que sua instância EC2 esteja acessível para administração e web, enquanto possibilita comunicação externa.

### 5. Criar Instância EC2

1. **Acesse o Console da AWS** e vá para a seção **EC2** e clique em **Launch Instance** para iniciar o processo de criação.
2. **Escolher a AMI**: Selecione **Ubuntu 20.04 LTS** 
3. **Escolher o Tipo de Instância**: Selecione uma instância de tipo `t2.micro` (nível gratuito)
4. Crie um par de chaves **RSA** em formato **.pem**
5. **Configurações de rede**:
   - Selecione a **VPC** criada anteriormente.
   - Selecione a **Sub-rede** e **atribua Ip público automaticamente**.
   - Selecione o **grupo de segurança** criado anteriormente.
6. **Armazenamento**: O armazenamento padrão de **8 GB** é suficiente.
7. Clique em **Revisar e Lançar**
   
### Explicações

- **Ubuntu 20.04 LTS**: Sistema operacional estável e recomendado para servidores.
- **Tipo t2.micro**:instância gratuita no **AWS Free Tier**, suficiente para este projeto.
- **Armazenamento**: 8 GB de EBS é adequado para sistemas pequenos. Pode ser expandido conforme necessário.
- **Par de chaves**: Essa chave permite acesso seguro à instância via SSH.

### 6. Conectar à Instância EC2 via SSH

1. **Prepare a Chave Privada**
   - No terminal, defina permissões para a chave privada:
     ```bash
     chmod 400 "sua-chave-privada.pem"
     ```

2. **Conectar via SSH**
   - Execute o comando abaixo, substituindo o caminho para a chave privada e o DNS público da sua instância:
     ```bash
     ssh -i "caminho-para-sua-chave.pem" ec2-user@seu-endereco-publico-ec2
     ```
---

## Parte 3. Instalando e configurando o Nginx

1. **Atualização do Sistema Ubuntu**
   - Primeiro, atualize a lista de pacotes e atualize os pacotes instalados para a versão mais recente:
   ```bash
   sudo apt update && sudo apt upgrade -y
   
2. **Instalando o Nginx**
   ```bash
   sudo apt install nginx -y

3.  **Verificando o Status do Nginx**
   - Se o Nginx estiver em execução, você verá uma saída indicando que o serviço está ativo (running).
     ```bash
     systemctl status nginx

   - Caso contrário, você pode iniciar o serviço com o comando:
     ```bash
     sudo systemctl start nginx

4.  **Habilite o Nginx para iniciar automaticamente**
    ```bash
    sudo systemctl enable nginx

5.  **Acessando o Nginx**
   - Após a instalação e ativação do Nginx, você pode acessar a página inicial do Nginx no navegador, digitando o endereço IP público da sua instância EC2 na barra de endereços.
   - 
---

## Parte 4. Criação do Script de Verificação

1. **Acesse o diretório de logs do Nginx e altere as permissões da pasta**
   ```bash
   sudo chmod 755 /var/log/nginx
   
2. **Crie o diretório para armazenar o Script**
   - Por boas práticas, scripts que têm impacto global no sistema devem ser armazenados em /usr/local/bin.
   ```bash
   cd /usr/local/bin
   sudo mkdir scripts
   cd scripts

3. **Crie o Script de verificação**
   ```bash
   sudo nano valida_nginx.sh
   
4. **Insira o seguinte código no arquivo**
   ```bash
   #!/bin/bash
    
    # Data e hora atuais
    DATA_HORA=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Nome do serviço
    SERVICO="nginx"
    
    # Diretório para os arquivos de saída
    DIR_LOG="/var/log/nginx"
    
    # Verificar status do serviço
    if systemctl is-active --quiet $SERVICO; then
        # Serviço está online
        echo "$DATA_HORA - $SERVICO - ONLINE - Serviço funcionando corretamente" >> $DIR_LOG/servico_online.log
    else
        # Serviço está offline
        echo "$DATA_HORA - $SERVICO - OFFLINE - Serviço indisponível" >> $DIR_LOG/servico_offline.log
    fi

- Salve o arquivo (Ctrl + O, Enter) e saia do editor (Ctrl + X)
   
5. **Deixe o script executável**
   ```bash
   sudo chmod +x valida_nginx.sh
   
---

## Parte 5. Automatizando o Script

 - Vamos configurar a execução automática do scirpt a cada 5 minutos utilizando o **cron**

1. **Edite o arquivo de tarefas agendadas do cron**
   ```bash
   crontab -e

- Ao executar `crontab -e` pela primeira vez, selecione o editor **nano** para facilitar a edição do arquivo.

2. **Adicione a seguinte linha ao final do arquivo**

   ```bash
    */5 * * * * /usr/local/bin/scripts/valida_nginx.sh

- O */5 * * * * no cron é uma expressão que define a frequência de execução do comando. Ela é dividida em cinco campos:

3. **Salve e saia do editor**

---

## Parte 6. Testando

1. **Verifique os arquivos de log no diretório /var/log/nginx**
   ```bash
   cat /var/log/nginx/servico_online.log
   cat /var/log/nginx/servico_offline.log

### Agora o script está configurado e será executado automaticamente a cada 5 minutos, registrando o status do serviço Nginx.



