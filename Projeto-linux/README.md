# Projeto: Monitoramento de Servidor com Nginx e Automação de Logs

## **Descrição**
Este projeto cria um ambiente Linux no Windows usando o WSL, configura um servidor Nginx rodando em uma instância EC2 da AWS, e implementa um script para monitorar o status do serviço Nginx, gerando logs automatizados.

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

## **Parte 2: Configuração da VPC**

### **1. Acessar o Console da AWS**
1. Faça login na sua conta AWS.
2. No painel principal, vá até **Serviços** e selecione **VPC**.

### **2. Criar a VPC**
1. Clique no botão **Criar VPC**.
2. Na próxima tela, selecione a opção **VPC e muito mais**.

### **3. Configurar os parâmetros da VPC**
Preencha os campos conforme indicado abaixo:

- **Nome da VPC**: Insira um nome descritivo, como `minha-vpc`.
- **Número de zonas de disponibilidade**: **2** (mantenha o padrão).
- **Número de sub-redes públicas**: **2**.
- **Número de sub-redes privadas**: **0**. (nesse projeto não utilizaremos sub-redes privadas)
- **NAT Gateways**: **Nenhum**.
- **Endpoints da VPC**: **Nenhum**.

### **4. Finalizar a criação**
1. Revise as configurações para garantir que estão corretas.
2. Clique no botão **Criar VPC**.
3. Aguarde o processo de criação ser concluído.

### Explicações

- **VPC**: Uma VPC é uma rede virtual isolada dentro da AWS, onde você pode executar recursos, como instâncias EC2, de forma segura. Criar uma VPC permite que você tenha controle sobre o tráfego de rede e defina a arquitetura de rede de acordo com as necessidades do seu projeto.
- **Zonas de Disponibilidade (AZs)**: As zonas de disponibilidade são locais fisicamente separados dentro de uma região. Ao distribuir seus recursos em múltiplas AZs, você aumenta a resiliência e a disponibilidade do seu ambiente. 
- **Subnets Públicas**: As subnets públicas são aquelas que têm acesso direto à Internet, essencial para a execução de servidores web, como o Nginx, ou outros serviços que precisam se comunicar com a Internet.
- **NAT Gateway**: O NAT Gateway permite que instâncias em subnets privadas acessem a Internet. No entanto, como não utilizaremos subnets privadas neste projeto, não será necessário configurar um NAT Gateway.
- **Endpoints da VPC**: Endpoints permitem que você se conecte a serviços da AWS de forma privada dentro da sua VPC, sem precisar passar pela Internet. No entanto, neste projeto, não há necessidade de configurar endpoints da VPC.

## Parte 3. Criar e Configurar o Grupo de Segurança

### Passos para Criar o Grupo de Segurança

1. **Acesse o Console de EC2** e vá para **Security Groups**.
2. **Crie um novo grupo**:
   - **Nome**: `meu-grupo-de-seguranca`
   - **Descrição**: `Grupo de segurança para controlar tráfego da EC2`
   - **Vincule à VPC** criada anteriormente.
3. **Adicionar Regras de Entrada**:
   - **SSH (porta 22)**: 
     - Fonte: `0.0.0.0/0` (acesso SSH de qualquer IP)
   - **HTTP (porta 80)**: 
     - Fonte: `0.0.0.0/0` (acesso HTTP público)
4. **Adicionar Regras de Saída**:
   - **Todo o tráfego**: 
     - Destino: `0.0.0.0/0` (permite tráfego de saída irrestrito)
5. **Revisar e Criar**.

## Explicações

- **SSH**: Liberar `0.0.0.0/0` é necessário para acessar a instância, mas recomenda-se restringir a um IP específico por segurança.
- **HTTP**: Liberar o tráfego HTTP de `0.0.0.0/0` permite acesso público ao servidor Nginx.
- **Saída**: Permitir todo tráfego de saída facilita a comunicação da instância com a internet, mas pode ser restrito conforme a necessidade de segurança.

Esse processo garante que sua instância EC2 esteja acessível para administração e web, enquanto possibilita comunicação externa.

# Parte 4. Criar Instância EC2

## Passos para Criar a Instância EC2

1. **Acesse o Console da AWS** e vá para a seção **EC2**.
2. Clique em **Launch Instance** para iniciar o processo de criação.
3. **Escolher a AMI (Imagem do Sistema Operacional)**:
   - Selecione uma imagem **Ubuntu 20.04 LTS** (ou versão mais recente disponível).
4. **Escolher o Tipo de Instância**:
   - Selecione uma instância de tipo `t2.micro` (dentro do **nível gratuito** se aplicável).
   - Crie um par de chaves **RSA** em formato **.pem**
5. **Configurações de rede**:
   - Selecione a **VPC** criada anteriormente.
   - Selecione a **Sub-rede** e **Atribua Ip público automaticamente**.
   - Clique em **selecionar o grupo de segurança existente** e selecione o grupo de segurança que criamos anteriormente.
6. **Adicionar Armazenamento**:
   - O armazenamento padrão de **8 GB** é suficiente para a maioria das necessidades iniciais.
7. **Associar Grupo de Segurança**:
   - Selecione o grupo de segurança **já criado**.
8. **Revisar e Lançar**:
   - Clique em **Launch**.

## Explicações

- **Ubuntu 20.04 LTS**: Essa versão é uma das mais populares e estável para servidores. Oferece suporte de longo prazo.
- **Tipo t2.micro**: Gratuito no nível AWS Free Tier, suficiente para testes e pequenos projetos.
- **Armazenamento**: 8 GB de EBS é adequado para sistemas pequenos. Pode ser expandido conforme necessário.
- **Par de chaves**: Essa chave permite acesso seguro à instância via SSH.


