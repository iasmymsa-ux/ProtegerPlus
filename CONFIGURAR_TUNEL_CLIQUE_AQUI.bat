@echo off
chcp 65001 >nul
title Configurar Proteger+ - URL Permanente
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║      CONFIGURAR URL PERMANENTE - PROTEGER+          ║
echo  ╚══════════════════════════════════════════════════════╝
echo.
echo  Este programa vai:
echo  1. Abrir o site da Cloudflare no seu navegador
echo  2. Voce clica em "Authorize" (autorizar)
echo  3. Pronto! URL permanente criada automaticamente
echo.
echo  ══════════════════════════════════════════════════════
echo  PASSO 1: Abrindo o navegador para fazer o login...
echo  ══════════════════════════════════════════════════════
echo.
echo  >>> Quando o navegador abrir, clique em AUTHORIZE <<<
echo.
pause

"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel login

echo.
echo  ══════════════════════════════════════════════════════
echo  PASSO 2: Criando tunel permanente...
echo  ══════════════════════════════════════════════════════
echo.
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel create proteger-plus

echo.
echo  ══════════════════════════════════════════════════════
echo  PASSO 3: Salvando configuracao...
echo  ══════════════════════════════════════════════════════
echo.

REM Salva o ID do tunel criado
for /f "tokens=*" %%a in ('"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel list 2^>^&1 ^| findstr "proteger-plus"') do set TUNNEL_INFO=%%a
echo Tunel encontrado: %TUNNEL_INFO%

echo.
echo  ══════════════════════════════════════════════════════
echo  ✓ TUDO PRONTO! 
echo  ══════════════════════════════════════════════════════
echo.
echo  Agora volte para o Antigravity e diga:
echo  "tunel configurado, pode continuar"
echo.
pause

