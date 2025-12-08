# Instruções para Fazer Push do Repositório

## Opção 1: Usar o Script PowerShell (Recomendado)

Execute o script que foi criado:

```powershell
.\setup-git.ps1
```

O script irá:
1. Verificar se o Git está instalado
2. Inicializar o repositório (se necessário)
3. Configurar o remote para o GitHub
4. Adicionar todos os arquivos
5. Fazer commit inicial
6. Fazer push para o GitHub

## Opção 2: Comandos Manuais

Se preferir fazer manualmente ou se o script não funcionar:

### 1. Verificar se Git está instalado

```powershell
git --version
```

Se não estiver instalado, baixe em: https://git-scm.com/download/win

### 2. Inicializar repositório (se ainda não foi feito)

```powershell
git init
```

### 3. Configurar remote

```powershell
git remote add origin git@github.com:faelelias/correcao_auto_devops.git
```

Ou se preferir HTTPS (mais fácil para primeira vez):

```powershell
git remote add origin https://github.com/faelelias/correcao_auto_devops.git
```

### 4. Adicionar arquivos

```powershell
git add .
```

### 5. Fazer commit

```powershell
git commit -m "chore: estrutura inicial - infra/app/ml/ci com AWS EKS, S3, CloudWatch, MongoDB e Grafana"
```

### 6. Configurar branch main

```powershell
git branch -M main
```

### 7. Fazer push

**Para SSH:**
```powershell
git push -u origin main
```

**Para HTTPS:**
```powershell
git push -u origin main
```
(Você precisará inserir suas credenciais do GitHub)

## Configurar Chave SSH (Opcional, mas recomendado)

Se quiser usar SSH sem precisar digitar senha toda vez:

1. Gerar chave SSH (se ainda não tiver):
```powershell
ssh-keygen -t ed25519 -C "seu-email@example.com"
```

2. Copiar chave pública:
```powershell
cat ~/.ssh/id_ed25519.pub
```

3. Adicionar no GitHub:
   - Vá em Settings > SSH and GPG keys
   - Clique em "New SSH key"
   - Cole a chave pública

## Verificar Status

Para ver o status do repositório:

```powershell
git status
```

Para ver os remotes configurados:

```powershell
git remote -v
```

