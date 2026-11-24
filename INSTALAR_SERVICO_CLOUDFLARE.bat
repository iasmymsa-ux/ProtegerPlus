@echo off
chcp 65001 >nul
title Instalar Servico Cloudflare - Proteger+
color 0A

echo.
echo  Instalando Cloudflare como servico automatico do Windows...
echo  (Requer permissao de Administrador - clique SIM se aparecer)
echo.

REM Instala o cloudflared como serviço Windows (inicia no boot automaticamente)
"C:\Program Files (x86)\cloudflared\cloudflared.exe" service install eyJhIjoiZmVkYjJlZjA2ZWFkMDQwZmMxMDk0YmQ0MTFjODAwYjQiLCJ0IjoiYTk4MjZkMDEtMTFjMS00NTEzLTlmZjItM2EzNzJiMjE3Y2Y3IiwicyI6IlpUUTRNemhqWW1ZdE5XTXdOaTAwT0RReUxXSTFPR1F0WmpRMVpqWmtNRFEzTmpZMlpXSXlNekkyTUdRdE5qUXhNeTAwWXpJMExUZzJaakl0TW1KbU4yTXlNR0V6T1dWaCJ9

echo.
if %ERRORLEVEL%==0 (
    color 0A
    echo  SUCESSO! Cloudflare instalado como servico do Windows!
    echo  Ele vai iniciar automaticamente toda vez que o PC ligar.
    echo.
    echo  Iniciando o servico agora...
    net start cloudflared
) else (
    color 0C
    echo  Falha na instalacao. Codigo: %ERRORLEVEL%
)
echo.
pause

