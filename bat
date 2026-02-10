@echo off
setlocal enabledelayedexpansion

REM === CONFIG ===
set LOG_FILE=C:\logs\s3_backup.log
set BKP_BASE=C:\dados\bkp

REM === ORIGENS ===
set SRC[1]=C:\dados\origem1
set SRC[2]=C:\dados\origem2
set SRC[3]=C:\dados\origem3
set SRC[4]=C:\dados\origem4
set SRC[5]=C:\dados\origem5
set SRC[6]=C:\dados\origem6

REM === DESTINOS S3 ===
set DST[1]=s3://meu-bucket/destino1/
set DST[2]=s3://meu-bucket/destino2/
set DST[3]=s3://meu-bucket/destino3/
set DST[4]=s3://meu-bucket/destino4/
set DST[5]=s3://meu-bucket/destino5/
set DST[6]=s3://meu-bucket/destino6/

echo ======================================== >> %LOG_FILE%
echo [%DATE% %TIME%] Inicio >> %LOG_FILE%

for %%I in (1 2 3 4 5 6) do (

    set SOURCE_DIR=!SRC[%%I]!
    set S3_BUCKET=!DST[%%I]!
    set BKP_DIR=%BKP_BASE%\origem%%I

    if not exist "!BKP_DIR!" mkdir "!BKP_DIR!"

    set LATEST_FILE=

    REM === PEGAR ARQUIVO MAIS RECENTE ===
    for /f "delims=" %%F in ('dir "!SOURCE_DIR!\*" /b /a-d /o-d') do (
        set LATEST_FILE=%%F
        goto :FOUND
    )

    :FOUND
    if not defined LATEST_FILE (
        echo [%DATE% %TIME%] Origem %%I: nenhum arquivo >> %LOG_FILE%
        goto :CONTINUE
    )

    REM === VERIFICAR SE JÁ FOI PROCESSADO ===
    if exist "!BKP_DIR!\!LATEST_FILE!" (
        echo [%DATE% %TIME%] Origem %%I: arquivo ja copiado (!LATEST_FILE!) >> %LOG_FILE%
        goto :CONTINUE
    )

    REM === UPLOAD S3 ===
    echo [%DATE% %TIME%] Origem %%I: enviando !LATEST_FILE! >> %LOG_FILE%
    aws s3 cp "!SOURCE_DIR!\!LATEST_FILE!" "!S3_BUCKET!!LATEST_FILE!" >> %LOG_FILE% 2>&1

    if !ERRORLEVEL! EQU 0 (
        REM === COPIA PARA BKP LOCAL ===
        copy "!SOURCE_DIR!\!LATEST_FILE!" "!BKP_DIR!\" >nul
        echo [%DATE% %TIME%] Origem %%I: upload e bkp OK >> %LOG_FILE%
    ) else (
        echo [%DATE% %TIME%] Origem %%I: ERRO upload >> %LOG_FILE%
    )

    :CONTINUE
)

echo [%DATE% %TIME%] Fim >> %LOG_FILE%
endlocal
