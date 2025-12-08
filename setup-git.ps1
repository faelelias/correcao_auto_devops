# Script para inicializar repositorio Git e fazer push inicial
# Execute: .\setup-git.ps1

$repoUrl = "git@github.com:faelelias/correcao_auto_devops.git"

Write-Host "Verificando Git..." -ForegroundColor Cyan

# Tentar encontrar Git em locais comuns
$gitPaths = @(
    "git",
    "C:\Program Files\Git\bin\git.exe",
    "C:\Program Files (x86)\Git\bin\git.exe"
)

$gitCmd = $null
foreach ($path in $gitPaths) {
    try {
        $result = & $path --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $gitCmd = $path
            Write-Host "Git encontrado: $gitCmd" -ForegroundColor Green
            break
        }
    } catch {
        continue
    }
}

if (-not $gitCmd) {
    Write-Host "ERRO: Git nao encontrado. Por favor, instale o Git:" -ForegroundColor Red
    Write-Host "https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Inicializando repositorio..." -ForegroundColor Cyan

# Verificar se ja e um repositorio Git
if (Test-Path .git) {
    Write-Host "Repositorio Git ja inicializado." -ForegroundColor Yellow
} else {
    & $gitCmd init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao inicializar repositorio" -ForegroundColor Red
        exit 1
    }
    Write-Host "Repositorio inicializado." -ForegroundColor Green
}

# Configurar remote
Write-Host ""
Write-Host "Configurando remote..." -ForegroundColor Cyan
& $gitCmd remote remove origin 2>$null
& $gitCmd remote add origin $repoUrl
Write-Host "Remote configurado: $repoUrl" -ForegroundColor Green

# Verificar configuração do Git
Write-Host ""
Write-Host "Verificando configuracao do Git..." -ForegroundColor Cyan
$userName = & $gitCmd config user.name 2>$null
$userEmail = & $gitCmd config user.email 2>$null

if ([string]::IsNullOrWhiteSpace($userName) -or [string]::IsNullOrWhiteSpace($userEmail)) {
    Write-Host "ATENCAO: Git nao esta configurado!" -ForegroundColor Red
    Write-Host "Execute os seguintes comandos antes de continuar:" -ForegroundColor Yellow
    Write-Host "  git config --global user.name `"Seu Nome`"" -ForegroundColor White
    Write-Host "  git config --global user.email `"seu-email@example.com`"" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou veja o arquivo CONFIGURAR_GIT.md para mais detalhes." -ForegroundColor Yellow
    exit 1
}

Write-Host "Git configurado: $userName <$userEmail>" -ForegroundColor Green

# Adicionar todos os arquivos
Write-Host ""
Write-Host "Adicionando arquivos..." -ForegroundColor Cyan
& $gitCmd add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro ao adicionar arquivos" -ForegroundColor Red
    exit 1
}

# Verificar se ha mudancas para commitar
$status = & $gitCmd status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Nenhuma mudanca para commitar." -ForegroundColor Yellow
} else {
    Write-Host "Fazendo commit inicial..." -ForegroundColor Cyan
    $commitMsg = "chore: estrutura inicial - infra/app/ml/ci com AWS EKS, S3, CloudWatch, MongoDB e Grafana"
    & $gitCmd commit -m $commitMsg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erro ao fazer commit" -ForegroundColor Red
        Write-Host "Verifique se o Git esta configurado (user.name e user.email)" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Commit realizado." -ForegroundColor Green
}

# Configurar branch main
Write-Host ""
Write-Host "Configurando branch main..." -ForegroundColor Cyan
& $gitCmd branch -M main 2>$null

# Push
Write-Host ""
Write-Host "Fazendo push para GitHub..." -ForegroundColor Cyan
Write-Host "NOTA: Voce precisara autenticar com SSH ou configurar credenciais." -ForegroundColor Yellow
& $gitCmd push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Push realizado com sucesso!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Erro no push. Verifique:" -ForegroundColor Yellow
    Write-Host "  1. Chave SSH configurada no GitHub" -ForegroundColor Yellow
    Write-Host "  2. Ou use HTTPS: git remote set-url origin https://github.com/faelelias/correcao_auto_devops.git" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Para tentar novamente, execute:" -ForegroundColor Cyan
    Write-Host "  git push -u origin main" -ForegroundColor White
}
