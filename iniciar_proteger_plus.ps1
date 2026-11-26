# ============================================================
#  PROTEGER+ - Watchdog & Startup Automático
#  Mantém MySQL (com auto-reparo Aria), Apache e Cloudflare
#  Quick Tunnel funcionando e publica api_endpoint.json
#  em UTF-8 SEM BOM no GitHub sempre que a URL mudar.
# ============================================================
param(
    [switch]$Watchdog
)

$repoDir         = "C:\Users\Iasmym\Downloads\proteger_plus"
$logFile         = "C:\xampp\proteger_plus_startup.log"
$pidFile         = "C:\xampp\proteger_plus_watchdog.pid"
$tunnelLog       = "C:\xampp\quick_tunnel.log"
$cfExe           = "C:\Program Files (x86)\cloudflared\cloudflared.exe"
$cfConfigYml     = "C:\Users\Iasmym\.cloudflared\config.yml"
$mysqlExe        = "C:\xampp\mysql\bin\mysqld.exe"
$mysqlCli        = "C:\xampp\mysql\bin\mysql.exe"
$ariaChkExe      = "C:\xampp\mysql\bin\aria_chk.exe"
$mysqlCfg        = "C:\xampp\mysql\bin\my.ini"
$mysqlDataDir    = "C:\xampp\mysql\data"
$apacheExe       = "C:\xampp\apache\bin\httpd.exe"
$apiEndpointFile = Join-Path $repoDir "api_endpoint.json"
$utf8NoBom       = New-Object System.Text.UTF8Encoding($false)
$script:cfBackoffUntil = [datetime]::MinValue

function Log($msg) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts  $msg"
    try {
        if ((Test-Path $logFile) -and ((Get-Item $logFile).Length -gt 204800)) {
            $tail = Get-Content $logFile -Tail 200 -ErrorAction SilentlyContinue
            [System.IO.File]::WriteAllLines($logFile, $tail, $utf8NoBom)
        }
        [System.IO.File]::AppendAllText($logFile, "$line`r`n", $utf8NoBom)
    } catch {}
    Write-Host $line
}

function Get-LocalLanIp {
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.InterfaceAlias -notmatch "Loopback|vEthernet|WSL|Hyper-V" -and
                $_.IPAddress -notlike "169.254.*" -and
                $_.IPAddress -ne "127.0.0.1"
            } |
            Select-Object -First 1).IPAddress
        if ($ip) { return $ip }
    } catch {}
    return "192.168.1.10"
}

function Test-MySqlReady {
    try {
        $out = & $mysqlCli -u root -e "SELECT 1" 2>&1
        return ($LASTEXITCODE -eq 0)
    } catch {
        return $false
    }
}

function Repair-MySqlAriaIfNeeded {
    $tables = @(
        "mysql\db.MAI",
        "mysql\global_priv.MAI",
        "mysql\proxies_priv.MAI",
        "mysql\roles_mapping.MAI",
        "mysql\tables_priv.MAI"
    )
    Push-Location $mysqlDataDir
    try {
        $checkOut = & $ariaChkExe -c @tables 2>&1
        if ($LASTEXITCODE -ne 0) {
            Log "[MySQL] Tabelas Aria corrompidas detectadas. Reparando automaticamente..."
            & $ariaChkExe -r --zerofill @tables 2>&1 | Out-Null
            Log "[MySQL] Reparo das tabelas de sistema concluido."
        }
    } finally {
        Pop-Location
    }
}

function Ensure-MySql {
    $procs = @(Get-Process -Name mysqld -ErrorAction SilentlyContinue)
    if ($procs.Count -gt 0) {
        if (Test-MySqlReady) {
            return $true
        }
        Log "[MySQL] Processo rodando mas recusando conexao (ex: erro 1130). Reiniciando e reparando..."
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }

    Repair-MySqlAriaIfNeeded
    Log "[MySQL] Iniciando servidor..."
    Start-Process -FilePath $mysqlExe -ArgumentList "--defaults-file=`"$mysqlCfg`" --standalone" -WindowStyle Hidden

    for ($i = 0; $i -lt 15; $i++) {
        Start-Sleep -Seconds 1
        if (Test-MySqlReady) {
            Log "[MySQL] Pronto e aceitando conexoes."
            return $true
        }
    }
    Log "[MySQL] AVISO: Nao respondeu em 15s."
    return $false
}

function Ensure-Apache {
    $procs = @(Get-Process -Name httpd -ErrorAction SilentlyContinue)
    if ($procs.Count -gt 0) { return $true }

    Log "[Apache] Iniciando..."
    Start-Process -FilePath $apacheExe -WindowStyle Hidden
    Start-Sleep -Seconds 3
    $ok = (@(Get-Process -Name httpd -ErrorAction SilentlyContinue).Count -gt 0)
    if ($ok) { Log "[Apache] OK" } else { Log "[Apache] FALHA ao iniciar" }
    return $ok
}

function Remove-BrokenCloudflareConfig {
    if (Test-Path $cfConfigYml) {
        $credPath = "C:\Users\Iasmym\.cloudflared\proteger-plus.json"
        if (-not (Test-Path $credPath)) {
            Log "[Cloudflare] Removendo config.yml orfao para evitar erro 404 no Quick Tunnel."
            Remove-Item $cfConfigYml -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-CurrentConfiguredApiUrl {
    try {
        if (Test-Path $apiEndpointFile) {
            $raw = [System.IO.File]::ReadAllText($apiEndpointFile, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF).Trim()
            $obj = $raw | ConvertFrom-Json
            if ($obj.api_url) { return $obj.api_url.ToString().TrimEnd('/') }
        }
    } catch {}
    return $null
}

function Test-ApiEndpoint($apiBaseUrl, [switch]$LogError) {
    if ([string]::IsNullOrWhiteSpace($apiBaseUrl)) { return $false }
    try {
        $resp = Invoke-RestMethod "$apiBaseUrl/health.php" -TimeoutSec 8 -ErrorAction Stop
        return ($resp.sucesso -eq $true)
    } catch {
        if ($LogError) {
            Log "[QuickTunnel] Check $apiBaseUrl falhou: $($_.Exception.Message)"
        }
        return $false
    }
}

function Save-And-PushEndpoint($apiUrl) {
    $payload = [ordered]@{
        api_url    = $apiUrl
        local_ip   = (Get-LocalLanIp)
        updated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    } | ConvertTo-Json
    [System.IO.File]::WriteAllText($apiEndpointFile, "$payload`n", $utf8NoBom)
    Log "[App] api_endpoint.json salvo sem BOM: $apiUrl"

    try {
        Push-Location $repoDir
        $diff = & git status --porcelain api_endpoint.json 2>&1
        if ($diff) {
            & git commit --only api_endpoint.json -m "auto: atualiza URL do tunel ($apiUrl)" 2>&1 | Out-Null
            & git push origin main 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Log "[Git] Push realizado com sucesso."
            } else {
                Log "[Git] Push falhou (exit $LASTEXITCODE); mantendo arquivo local."
            }
        }
    } catch {
        Log "[Git] Erro no push: $_"
    } finally {
        Pop-Location
    }
}

function Get-TunnelUrlFromLog {
    if (Test-Path $tunnelLog) {
        $content = Get-Content $tunnelLog -Raw -ErrorAction SilentlyContinue
        if ($content -match 'https://([a-z0-9]+-[a-z0-9\-]+\.trycloudflare\.com)') {
            return "https://$($Matches[1])"
        }
    }
    return $null
}

function Ensure-QuickTunnel {
    Remove-BrokenCloudflareConfig

    $userTunnels = @(Get-Process cloudflared -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -ne 0 })
    $currentApiUrl = Get-CurrentConfiguredApiUrl

    $logHasDeadTunnel = $false
    if (Test-Path $tunnelLog) {
        $tailLog = Get-Content $tunnelLog -Tail 25 -ErrorAction SilentlyContinue | Out-String
        if ($tailLog -match "Unauthorized: Tunnel not found|status 429|Tunnelstore request failed") {
            $logHasDeadTunnel = $true
        }
    }

    if (-not $logHasDeadTunnel -and $userTunnels.Count -gt 0) {
        if (Test-ApiEndpoint $currentApiUrl) {
            return $true
        }
        # Se o cloudflared ja tem uma URL no log que apenas demorou para propagar DNS, resgata sem matar
        $logHostUrl = Get-TunnelUrlFromLog
        if ($logHostUrl) {
            $logApiUrl = "$logHostUrl/proteger_plus_api"
            if (Test-ApiEndpoint $logApiUrl) {
                Log "[QuickTunnel] Tunel em execucao recuperado e validado: $logApiUrl"
                Save-And-PushEndpoint $logApiUrl
                return $true
            }
        }
        Start-Sleep -Seconds 6
        if ((Test-ApiEndpoint $currentApiUrl) -or ($logHostUrl -and (Test-ApiEndpoint "$logHostUrl/proteger_plus_api"))) {
            if ($logHostUrl -and ($logHostUrl + "/proteger_plus_api") -ne $currentApiUrl) {
                Save-And-PushEndpoint "$logHostUrl/proteger_plus_api"
            }
            return $true
        }
    }

    # Se estamos em cooldown por rate limit (HTTP 429), nao martela a API do Cloudflare
    if ((Get-Date) -lt $script:cfBackoffUntil) {
        return $false
    }

    Log "[QuickTunnel] Iniciando novo Quick Tunnel (SessionId != 0)..."
    Get-Process cloudflared -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -ne 0 } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (Test-Path $tunnelLog) { Remove-Item $tunnelLog -Force -ErrorAction SilentlyContinue }

    Start-Process -FilePath $cfExe `
        -ArgumentList "tunnel --no-autoupdate --url http://localhost --metrics 127.0.0.1:20242" `
        -RedirectStandardError $tunnelLog `
        -WindowStyle Hidden

    $hostUrl = $null
    $rateLimited = $false
    for ($i = 0; $i -lt 25 -and -not $hostUrl; $i++) {
        Start-Sleep -Seconds 2
        if (Test-Path $tunnelLog) {
            $content = Get-Content $tunnelLog -Raw -ErrorAction SilentlyContinue
            if ($content -match 'https://([a-z0-9]+-[a-z0-9\-]+\.trycloudflare\.com)') {
                $hostUrl = "https://$($Matches[1])"
            } elseif ($content -match 'status 429|Tunnelstore request failed') {
                $rateLimited = $true
                break
            }
        }
    }

    if ($rateLimited) {
        Get-Process cloudflared -ErrorAction SilentlyContinue | Where-Object { $_.SessionId -ne 0 } | Stop-Process -Force -ErrorAction SilentlyContinue
        $script:cfBackoffUntil = (Get-Date).AddMinutes(5)
        Log "[QuickTunnel] Rate limit Cloudflare (429). Aguardando 5 minutos antes de tentar novo tunel."
        return $false
    }

    if (-not $hostUrl) {
        Log "[QuickTunnel] AVISO: Nao foi possivel obter URL do tunel em 50s."
        return $false
    }

    $apiUrl = "$hostUrl/proteger_plus_api"
    Log "[QuickTunnel] URL capturada: $apiUrl. Aguardando 8s para propagacao DNS..."
    Start-Sleep -Seconds 8
    ipconfig /flushdns | Out-Null

    $verified = $false
    for ($try = 1; $try -le 20; $try++) {
        if (Test-ApiEndpoint $apiUrl -LogError:($try -eq 1 -or $try -eq 10 -or $try -eq 20)) {
            $verified = $true
            break
        }
        ipconfig /flushdns | Out-Null
        Start-Sleep -Seconds 3
    }

    if ($verified) {
        Log "[QuickTunnel] Tunel validado fim-a-fim (HTTP 200 OK)."
        Save-And-PushEndpoint $apiUrl
        return $true
    }

    Log "[QuickTunnel] AVISO: Tunel ($apiUrl) ainda propagando DNS; sera retestado sem matar o processo."
    return $false
}

function Invoke-Cycle {
    Ensure-MySql | Out-Null
    Ensure-Apache | Out-Null
    Ensure-QuickTunnel | Out-Null
}

if ($Watchdog) {
    if (Test-Path $pidFile) {
        $oldPid = (Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1) -as [int]
        if ($oldPid -and $oldPid -ne $PID) {
            $existing = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
            if ($existing -and $existing.ProcessName -match "powershell") {
                Log "[Watchdog] Ja existe watchdog ativo (PID $oldPid). Saindo."
                exit 0
            }
        }
    }
    [System.IO.File]::WriteAllText($pidFile, "$PID", $utf8NoBom)
    Log "=== PROTEGER+ WATCHDOG INICIADO (PID $PID) ==="

    try {
        while ($true) {
            Invoke-Cycle
            Start-Sleep -Seconds 30
        }
    } finally {
        if ((Get-Content $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1) -eq "$PID") {
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        }
    }
} else {
    Log "=== PROTEGER+ STARTUP UNICO ==="
    Invoke-Cycle
    Log "=== STARTUP CONCLUIDO ==="
}
