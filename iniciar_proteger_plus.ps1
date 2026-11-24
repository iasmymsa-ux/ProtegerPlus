# ============================================================
#  PROTEGER+ - Script de inicialização automática completa
#  Inicia: MySQL, Apache e Cloudflare Tunnel (URL permanente)
#  Rodado automaticamente pelo Windows no boot.
# ============================================================

$logFile = "C:\xampp\proteger_plus_startup.log"
$cloudflaredExe = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
$mysqlExe   = "C:\xampp\mysql\bin\mysqld.exe"
$mysqlCfg   = "C:\xampp\mysql\bin\my.ini"
$apacheExe  = "C:\xampp\apache\bin\httpd.exe"

# Arquivo que o app Flutter lê para saber a URL atual do túnel
$apiEndpointFile = "C:\Users\Iasmym\Downloads\proteger_plus\api_endpoint.json"
$repoEndpointFile = "C:\Users\Iasmym\Downloads\proteger_plus\lib\services\api_config.dart"

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts  $msg" | Out-File -Append -FilePath $logFile
    Write-Host "$ts  $msg"
}

function IsRunning($procName) {
    return @(Get-Process -Name $procName -ErrorAction SilentlyContinue).Count -gt 0
}

Log "=== PROTEGER+ STARTUP ==="

# --- 1. MySQL ---
if (IsRunning "mysqld") {
    Log "[MySQL] Já está rodando."
} else {
    Log "[MySQL] Iniciando..."
    Start-Process -FilePath $mysqlExe -ArgumentList "--defaults-file=`"$mysqlCfg`" --standalone" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    if (IsRunning "mysqld") { Log "[MySQL] OK" } else { Log "[MySQL] FALHA ao iniciar" }
}

# --- 2. Apache ---
if (IsRunning "httpd") {
    Log "[Apache] Já está rodando."
} else {
    Log "[Apache] Iniciando..."
    Start-Process -FilePath $apacheExe -WindowStyle Hidden
    Start-Sleep -Seconds 3
    if (IsRunning "httpd") { Log "[Apache] OK" } else { Log "[Apache] FALHA ao iniciar" }
}

# --- 3. Cloudflare Tunnel ---
# Verifica se já existe um túnel com nome fixo configurado
$namedTunnelConfig = "C:\Users\Iasmym\.cloudflared\config.yml"
$useNamedTunnel = Test-Path $namedTunnelConfig

if (IsRunning "cloudflared") {
    Log "[Cloudflare] Tunnel já está rodando."
} else {
    if ($useNamedTunnel) {
        # Túnel nomeado (URL permanente) - melhor opção
        Log "[Cloudflare] Iniciando túnel nomeado (URL permanente)..."
        Start-Process -FilePath $cloudflaredExe -ArgumentList "tunnel run" -WindowStyle Hidden
        Log "[Cloudflare] Túnel nomeado iniciado."
    } else {
        # Túnel temporário - captura a URL e atualiza os arquivos do app
        Log "[Cloudflare] Iniciando túnel temporário (sem conta configurada)..."
        $tunnelLog = "C:\xampp\cloudflare_tunnel.log"

        # Para qualquer processo antigo
        Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force

        # Inicia e redireciona saída para arquivo de log
        $proc = Start-Process -FilePath $cloudflaredExe `
            -ArgumentList "tunnel --url http://localhost" `
            -RedirectStandardError $tunnelLog `
            -WindowStyle Hidden -PassThru

        Log "[Cloudflare] Aguardando URL do túnel..."
        $url = $null
        $tries = 0
        while ($tries -lt 30 -and -not $url) {
            Start-Sleep -Seconds 2
            $tries++
            if (Test-Path $tunnelLog) {
                $content = Get-Content $tunnelLog -Raw -ErrorAction SilentlyContinue
                if ($content -match 'https://([a-z0-9\-]+\.trycloudflare\.com)') {
                    $url = "https://$($Matches[1])"
                }
            }
        }

        if ($url) {
            $apiUrl = "$url/proteger_plus_api"
            Log "[Cloudflare] URL obtida: $apiUrl"

            # Atualiza api_endpoint.json (lido pelo app via GitHub)
            $json = @{
                api_url    = $apiUrl
                local_ip   = "192.168.1.10"
                updated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            } | ConvertTo-Json
            $json | Out-File -FilePath $apiEndpointFile -Encoding utf8 -Force

            Log "[App] api_endpoint.json atualizado com nova URL."

            # Faz git add + commit + push automático para o GitHub
            # Assim o app Flutter lê a URL nova na próxima abertura
            try {
                Set-Location "C:\Users\Iasmym\Downloads\proteger_plus"
                & git add api_endpoint.json 2>&1 | Out-Null
                & git commit -m "auto: atualiza URL do tunel Cloudflare ($apiUrl)" 2>&1 | Out-Null
                & git push origin main 2>&1 | Out-Null
                Log "[Git] Push realizado com nova URL do túnel."
            } catch {
                Log "[Git] Falha no push: $_"
            }
        } else {
            Log "[Cloudflare] AVISO: Não foi possível capturar a URL do túnel em 60s."
        }
    }
}

Log "=== STARTUP CONCLUÍDO ==="

