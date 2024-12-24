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
