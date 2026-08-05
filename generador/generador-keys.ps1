# =============================================================
#  VPS LICENSE GATE - GENERADOR DE KEYS (SOLO VENDEDOR)
#  -------------------------------------------------------------
#  HERRAMIENTA PRIVADA - NO subir a GitHub (usa config privada).
#  Genera una key de licencia, la sube a Firebase RTDB con
#  expiracion = hoy + N dias (default 30).
#
#  USO:
#    .\generador-keys.ps1                      # modo interactivo
#    .\generador-keys.ps1 -Cliente "Juan" -Dias 30
#    .\generador-keys.ps1 -Dias 90 -Cliente "Tienda X" -Auto
#
#  NOTA: archivo 100% ASCII para compatibilidad con PS 5.1
# =============================================================

param(
    [string]$Cliente = "",
    [int]$Dias = 30,
    [switch]$Auto        # genera sin preguntar (usa los parametros dados)
)

# ================= CONFIGURACION =================
# Cargar configuracion privada (NO subir a GitHub)
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_FILE = Join-Path $SCRIPT_DIR "config-generador.ps1"
if (Test-Path -LiteralPath $CONFIG_FILE) {
    . $CONFIG_FILE
} else {
    Write-Host "[ERR] No existe config-generador.ps1. Copia la plantilla config-generador.ps1.example y configurala." -ForegroundColor Red
    exit 1
}

# ================= FUNCIONES =================
function Write-OK   { Write-Host "[OK] $($args[0])" -ForegroundColor Green }
function Write-ERR  { Write-Host "[ERR] $($args[0])" -ForegroundColor Red }
function Write-INFO { Write-Host "[->] $($args[0])" -ForegroundColor Cyan }
function Write-WARN { Write-Host "[!] $($args[0])" -ForegroundColor Yellow }

function New-LicenseKey {
    # Genera KEY-XXXXXXXXXX (10 hex aleatorios)
    $hex = ""
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] 5
    $rng.GetBytes($bytes)
    foreach ($b in $bytes) { $hex += $b.ToString("X2") }
    return "KEY-$hex"
}

function Get-UnixTime {
    param([DateTime]$Date)
    return [int64]([DateTimeOffset]$Date.ToUniversalTime()).ToUnixTimeSeconds()
}

# ================= MAIN =================
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   GENERADOR DE LICENCIAS - VPS LICENSE GATE" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Pedir datos si no vienen
if (-not $Auto) {
    if ([string]::IsNullOrEmpty($Cliente)) {
        $Cliente = Read-Host "Nombre del cliente (Enter para anonimo)"
    }
    $diasInput = Read-Host "Dias de validez (default 30)"
    if ($diasInput -match '^\d+$') { $Dias = [int]$diasInput }
}

if ($Dias -lt 1) { $Dias = $DIAS_DEFAULT }

# Generar key
$KEY = New-LicenseKey
$ahora = Get-Date
$expira = $ahora.AddDays($Dias)
$expiraEpoch = Get-UnixTime -Date $expira
$creadaEpoch = Get-UnixTime -Date $ahora
$clienteFinal = if ([string]::IsNullOrEmpty($Cliente)) { "anonimo" } else { $Cliente }

Write-INFO "Cliente : $clienteFinal"
Write-INFO "Dias    : $Dias"
Write-INFO "Expira  : $($expira.ToString('yyyy-MM-dd HH:mm'))"
Write-INFO "Key     : $KEY"

# Construir JSON
$body = @{
    activa  = $true
    creada  = $creadaEpoch
    expira  = $expiraEpoch
    cliente = $clienteFinal
    plan    = $PLAN_DEFAULT
} | ConvertTo-Json

# Subir a Firebase
Write-INFO "Subiendo a Firebase..."
$url = "https://$FB_BASE/$FB_LICENCIAS/$KEY.json"
try {
    $resp = Invoke-RestMethod -Uri $url -Method Put -Body $body -ContentType "application/json" -TimeoutSec 20
    Write-OK "Key subida correctamente a Firebase"
    Write-OK "Respuesta del servidor: $($resp | ConvertTo-Json -Compress)"
} catch {
    Write-ERR "Error al subir a Firebase: $($_.Exception.Message)"
    Write-ERR "La key NO fue creada. Revisa conexion y reintenta."
    exit 1
}

# Mostrar resultado final
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "   ENTREGAR AL CLIENTE:" -ForegroundColor Green
Write-Host ""
Write-Host "   KEY DE LICENCIA:  $KEY" -ForegroundColor White -BackgroundColor DarkGreen
Write-Host "   Valida hasta:     $($expira.ToString('yyyy-MM-dd HH:mm'))"
Write-Host ""
Write-Host "   El cliente puede instalar en TODAS las VPS que quiera"
Write-Host "   durante este periodo. Despues, la key ya no instala."
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Copiar al portapapeles si posible
try {
    Set-Clipboard -Value $KEY
    Write-INFO "Key copiada al portapapeles"
} catch { }
