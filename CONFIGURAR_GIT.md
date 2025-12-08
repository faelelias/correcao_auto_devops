# Configurar Git e Fazer Push

## Passo 1: Configurar Identidade do Git

Antes de fazer commit, configure seu nome e email:

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@example.com"
```

Ou apenas para este repositório (sem --global):

```powershell
git config user.name "Seu Nome"
git config user.email "seu-email@example.com"
```

## Passo 2: Executar Script de Setup

Depois de configurar o Git, execute:

```powershell
.\setup-git.ps1
```

## Passo 3: Se o Push Falhar (SSH)

Se você ainda não configurou chave SSH no GitHub, use HTTPS:

```powershell
git remote set-url origin https://github.com/faelelias/correcao_auto_devops.git
git push -u origin main
```

Você precisará inserir seu usuário e token do GitHub.

## Alternativa: Comandos Manuais

Se preferir fazer tudo manualmente:

```powershell
# 1. Configurar usuário (se ainda não fez)
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@example.com"

# 2. Verificar se já é um repositório Git
git status

# 3. Se não for, inicializar
git init

# 4. Configurar remote
git remote add origin https://github.com/faelelias/correcao_auto_devops.git

# 5. Adicionar arquivos
git add .

# 6. Fazer commit
git commit -m "chore: estrutura inicial - infra/app/ml/ci com AWS EKS, S3, CloudWatch, MongoDB e Grafana"

# 7. Configurar branch main
git branch -M main

# 8. Fazer push
git push -u origin main
```

