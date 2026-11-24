@echo off
chcp 65001 >nul
title Configurar Tunel Permanente - Proteger+
color 0A
echo.
echo  ============================================================
echo   PASSO 1: Fazer login na Cloudflare (gratuito)
echo  ============================================================
echo.
echo  Isso vai abrir o navegador para voce criar/logar na Cloudflare.
echo  A conta e GRATUITA e nao precisa de cartao de credito.
echo.
echo  Pressione qualquer tecla para abrir o navegador...
pause >nul
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel login
echo.
echo  ============================================================
echo   PASSO 2: Criando tunel permanente "proteger-plus"
echo  ============================================================
echo.
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel create proteger-plus
echo.
echo  ============================================================
echo   PASSO 3: Configurando rota para localhost
echo  ============================================================
echo.
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel route dns proteger-plus proteger-plus
echo.
echo  ============================================================
echo   Tunel criado! Verificando...
echo  ============================================================
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel list
echo.
echo  Pressione qualquer tecla para fechar.
pause >nul

