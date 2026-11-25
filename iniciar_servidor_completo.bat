@echo off
chcp 65001 > nul
title Proteger+ Servidor, Banco de Dados e Tunel Online
color 0B

echo =========================================================
echo    INICIANDO PROTEGER+ (MYSQL + APACHE + TUNEL ONLINE)
echo =========================================================
echo.
echo Verificando e iniciando servicos em segundo plano...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Iasmym\Downloads\proteger_plus\iniciar_proteger_plus.ps1"

echo.
echo Garantindo watchdog automatico ativo...
start "" /MIN powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Iasmym\Downloads\proteger_plus\iniciar_proteger_plus.ps1" -Watchdog

echo.
echo =========================================================
echo  Endpoint publico atual (api_endpoint.json):
type "C:\Users\Iasmym\Downloads\proteger_plus\api_endpoint.json"
echo =========================================================
echo.
echo  Pode fechar esta janela - os servicos continuam ativos!
pause
