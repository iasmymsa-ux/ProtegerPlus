@echo off
chcp 65001 >nul
title Login Cloudflare - Proteger+
color 0E

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║          LOGIN CLOUDFLARE - PASSO A PASSO           ║
echo  ╚══════════════════════════════════════════════════════╝
echo.
echo  IMPORTANTE: Siga exatamente estes passos:
echo.
echo  1. Pressione ENTER abaixo
echo  2. O NAVEGADOR vai abrir com o site da Cloudflare
echo  3. Faca login (ou crie uma conta gratuita)
echo  4. Depois do login, vai aparecer uma lista de sites
echo     Clique em qualquer site listado (ou "Authorize")
echo  5. Aguarde a mensagem "You have successfully logged in"
echo  6. VOLTE AQUI e pressione ENTER novamente
echo.
echo  Pressione ENTER para abrir o navegador...
pause >nul

echo.
echo  Abrindo navegador...
"C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel login

echo.
echo  ══════════════════════════════════════════════════════
if exist "C:\Users\Iasmym\.cloudflared\cert.pem" (
    color 0A
    echo  LOGIN REALIZADO COM SUCESSO!
    echo  O arquivo de certificado foi criado.
    echo.
    echo  Agora criando o tunel permanente...
    "C:\Program Files (x86)\cloudflared\cloudflared.exe" tunnel create proteger-plus
    echo.
    echo  PRONTO! Volte para o Antigravity e diga "pronto"
) else (
    color 0C
    echo  LOGIN NAO CONCLUIDO.
    echo  Tente novamente - clique em "Authorize" no navegador
    echo  antes de voltar para esta janela.
)
echo  ══════════════════════════════════════════════════════
echo.
pause

