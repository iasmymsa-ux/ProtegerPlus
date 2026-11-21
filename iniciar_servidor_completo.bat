@echo off
chcp 65001 > nul
title Proteger+ Servidor e Banco de Dados
color 0B

echo =========================================================
echo    INICIANDO SERVIDOR E BANCO DE DADOS - PROTEGER+
echo =========================================================
echo.

echo [1/3] Verificando e iniciando MySQL (XAMPP)...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I /N "mysqld.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo  -> MySQL ja esta em execucao!
) else (
    start "" /B "C:\xampp\mysql\bin\mysqld.exe" --defaults-file=C:\xampp\mysql\bin\my.ini --standalone
    echo  -> MySQL iniciado com sucesso!
)

echo.
echo [2/3] Verificando e iniciando Apache (XAMPP)...
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo  -> Apache ja esta em execucao!
) else (
    start "" /B "C:\xampp\apache\bin\httpd.exe"
    echo  -> Apache iniciado com sucesso!
)

echo.
echo [3/3] IP atual deste computador na rede Wi-Fi:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    echo  -> Endereco de rede: http:%%a/proteger_plus_api
)

echo.
echo =========================================================
echo  STATUS: Banco de dados e API estao ativos e prontos!
echo  Para conexao remota (4G/5G/qualquer lugar):
echo  Se desejar abrir o tunel Cloudflare, execute:
echo  cloudflared tunnel --url http://localhost
echo =========================================================
echo.
pause

