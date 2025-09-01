# # 🌐 WebIO - Static Website Hosting on AWS

Este projeto implementa uma solução completa de hospedagem de site estático
na AWS usando S3, CloudFront e automação CI/CD.

## 🚀 Pipeline Status

A pipeline foi corrigida para executar o deploy automaticamente quando há
mudanças na infraestrutura!

## 🏗️ Arquitetura

- **S3 Bucket**: Hospedagem dos arquivos estáticos
- **CloudFront**: CDN global com HTTPS
- **S3 Backend**: State do Terraform
- **GitHub Actions**: CI/CD Pipeline

## 🚀 URLs do Site

- **CloudFront (HTTPS)**: https://d3u1rxjncb1m39.cloudfront.net
- **S3 Website**: http://webio-mfdemenezes.s3-website-us-east-1.amazonaws.com

## ⚙️ Configuração da Pipeline

### 1. Secrets do GitHub

Configure os seguintes secrets no repositório:

```
AWS_ACCESS_KEY_ID     = sua_access_key
AWS_SECRET_ACCESS_KEY = sua_secret_key
```

**Como configurar:**
1. Vá em `Settings` → `Secrets and variables` → `Actions`
2. Clique em `New repository secret`
3. Adicione cada secret

### 2. Environment Protection

Configure o environment `production`:
1. Vá em `Settings` → `Environments`
2. Crie environment `production`
3. Adicione protection rules (opcional)

## 🔄 Como Funciona a Pipeline

### Deploy Automático
```
git push origin main
```
- ✅ Valida sintaxe do Terraform
- ✅ Executa `terraform plan`
- ✅ Aplica mudanças automaticamente
- ✅ Invalida cache do CloudFront
- ✅ Mostra URLs atualizadas

### Deploy Manual
1. Vá em `Actions`
2. Selecione `Deploy Infrastructure and Website`
3. Clique em `Run workflow`

### Destruir Infraestrutura
1. Vá em `Actions`
2. Selecione `🗑️ Destroy Infrastructure`
3. Digite `DESTROY` para confirmar
4. Clique em `Run workflow`

## 📁 Estrutura do Projeto

```
.
├── .github/workflows/    # Pipelines CI/CD
│   ├── deploy.yml       # Deploy principal
│   └── destroy.yml      # Destruição segura
├── terraform/           # Código Terraform (S3)
├── main.tf             # Infraestrutura principal
├── providers.tf        # Providers AWS
├── variables.tf        # Variáveis
├── outputs.tf          # Outputs
├── terraform.tfvars    # Configurações
├── index.html          # Site principal
├── *.pdf              # Documentos
└── *.png              # Imagens
```

## 🛠️ Desenvolvimento Local

### Pré-requisitos
- Terraform >= 1.6.0
- AWS CLI configurado
- Credenciais AWS válidas

### Deploy Local
```bash
# Inicializar
terraform init

# Planejar
terraform plan

# Aplicar
terraform apply

# Destruir
terraform destroy
```

## 📊 Monitoramento

### Logs da Pipeline
- ✅ Validação de sintaxe
- ✅ Plan detalhado
- ✅ Outputs de URLs
- ✅ Status de deployment

### Invalidação de Cache
- ✅ CloudFront cache é limpo automaticamente
- ✅ Mudanças visíveis em ~2-5 minutos

## 🔒 Segurança

- ✅ S3 Backend com criptografia
- ✅ DynamoDB State Locking
- ✅ HTTPS obrigatório via CloudFront
- ✅ Secrets protegidos no GitHub
- ✅ Environment protection para production

## 💰 Custos AWS

**Free Tier Incluso:**
- S3: 5GB storage
- CloudFront: 1TB transfer + 10M requests
- DynamoDB: 25GB storage

**Estimativa mensal:** ~$0-5 USD

## 🤝 Como Contribuir

1. Fork do repositório
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'Add nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT.
