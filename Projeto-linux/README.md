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

## **Parte 2: Configuração da VPC na AWS**

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

## Parte 4. Criar e Configurar o Grupo de Segurança

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


