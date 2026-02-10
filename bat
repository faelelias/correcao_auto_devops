@echo off
setlocal

set SOURCE_DIR=C:\dados\origem1
set BKP_DIR=C:\dados\bkp\origem1
set S3_BUCKET=s3://meu-bucket/destino1/
set LOG_FILE=C:\logs\teste.log

if not exist "%BKP_DIR%" mkdir "%BKP_DIR%"

echo [%DATE% %TIME%] Inicio >> %LOG_FILE%

for /f "delims=" %%F in ('dir "%SOURCE_DIR%\*" /b /a-d /o-d') do (
    set LATEST_FILE=%%F
    goto :FOUND
)

:FOUND
if not defined LATEST_FILE (
    echo Nenhum arquivo encontrado >> %LOG_FILE%
    goto :EOF
)

if exist "%BKP_DIR%\%LATEST_FILE%" (
    echo Arquivo ja existe no BKP >> %LOG_FILE%
    goto :EOF
)

echo Enviando %LATEST_FILE% >> %LOG_FILE%

aws s3 cp "%SOURCE_DIR%\%LATEST_FILE%" "%S3_BUCKET%%LATEST_FILE%" >> %LOG_FILE% 2>&1

if %ERRORLEVEL% EQU 0 (
    copy "%SOURCE_DIR%\%LATEST_FILE%" "%BKP_DIR%\" >nul
    echo Upload e BKP OK >> %LOG_FILE%
) else (
    echo ERRO upload >> %LOG_FILE%
)

echo Fim >> %LOG_FILE%
endlocal
