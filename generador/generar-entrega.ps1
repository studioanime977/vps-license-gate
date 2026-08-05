# =============================================================
#  GENERADOR DE ENTREGA COMPLETA - VPS LICENSE GATE
#  -------------------------------------------------------------
#  HERRAMIENTA PRIVADA DEL VENDEDOR - NO subir a GitHub.
#  Genera una key, la sube a Firebase y crea el documento de
#  entrega para el cliente (con caracteristicas + key + fechas),
#  listo para copiar y pegar en WhatsApp/Telegram.
#
#  USO:
#    .\generar-entrega.ps1 -Cliente "Juan" -Dias 30
#    .\generar-entrega.ps1 -Cliente "Tienda X" -Dias 90
#    .\generar-entrega.ps1                      # modo interactivo
#
#  NOTA: archivo 100% ASCII para compatibilidad con PS 5.1.
#  La plantilla SI puede llevar emojis (se lee en UTF-8).
# =============================================================

param(
    [string]$Cliente = "",
    [int]$Dias = 30
)

# ================= CONFIGURACION =================
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CONFIG_FILE = Join-Path $SCRIPT_DIR "config-generador.ps1"
if (Test-Path -LiteralPath $CONFIG_FILE) {
    . $CONFIG_FILE
} else {
    Write-Host "[ERR] No existe config-generador.ps1. Copia la plantilla config-generador.ps1.example y configurala." -ForegroundColor Red
    exit 1
}

$PLANTILLA = Join-Path $SCRIPT_DIR "plantilla-entrega.md"
$OUTPUT_DIR = Join-Path $SCRIPT_DIR "entregas"
if (-not (Test-Path -LiteralPath $OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $OUTPUT_DIR | Out-Null
}

# ================= FUNCIONES =================
function Write-OK   { Write-Host "[OK] $($args[0])" -ForegroundColor Green }
function Write-ERR  { Write-Host "[ERR] $($args[0])" -ForegroundColor Red }
function Write-INFO { Write-Host "[->] $($args[0])" -ForegroundColor Cyan }
function Write-WARN { Write-Host "[!] $($args[0])" -ForegroundColor Yellow }

function New-LicenseKey {
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
Write-Host "   GENERADOR DE ENTREGA - VPS LICENSE GATE" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Pedir datos si no vienen
if ([string]::IsNullOrEmpty($Cliente)) {
    $Cliente = Read-Host "Nombre del cliente (Enter para anonimo)"
}
$diasInput = Read-Host "Dias de validez (default 30)"
if ($diasInput -match '^\d+$') { $Dias = [int]$diasInput }
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
Write-INFO "Key     : $KEY"

# Subir a Firebase
$body = @{
    activa  = $true
    creada  = $creadaEpoch
    expira  = $expiraEpoch
    cliente = $clienteFinal
    plan    = $PLAN_DEFAULT
} | ConvertTo-Json

Write-INFO "Subiendo a Firebase..."
$url = "https://$FB_BASE/$FB_LICENCIAS/$KEY.json"
try {
    $resp = Invoke-RestMethod -Uri $url -Method Put -Body $body -ContentType "application/json" -TimeoutSec 20
    Write-OK "Key subida correctamente a Firebase"
} catch {
    Write-ERR "Error al subir a Firebase: $($_.Exception.Message)"
    Write-ERR "La key NO fue creada. Revisa conexion y reintenta."
    exit 1
}

# Crear documento de entrega
if (-not (Test-Path -LiteralPath $PLANTILLA)) {
    Write-ERR "No existe plantilla-entrega.md junto a este script."
    exit 1
}

try {
    $plantilla = [System.IO.File]::ReadAllText($PLANTILLA, [System.Text.Encoding]::UTF8)
    $plantilla = $plantilla.Replace("{{KEY}}", $KEY)
    $plantilla = $plantilla.Replace("{{DIAS}}", "$Dias")
    $plantilla = $plantilla.Replace("{{INICIO}}", $ahora.ToString('dd/MM/yyyy'))
    $plantilla = $plantilla.Replace("{{FIN}}", $expira.ToString('dd/MM/yyyy'))

    # Nombre del archivo usa el nombre del cliente que colocaste (limpiado de caracteres raros)
    $nombreLimpio = ($clienteFinal -replace '[^a-zA-Z0-9 ]', '') -replace '\s+', ' '
    $nombreArchivo = "$nombreLimpio.txt"
    $rutaSalida = Join-Path $OUTPUT_DIR $nombreArchivo

    # Si ya existe, agregar numero para no sobreescribir
    $contador = 2
    $rutaFinal = $rutaSalida
    while (Test-Path -LiteralPath $rutaFinal) {
        $nombreArchivo = "$nombreLimpio-$contador.txt"
        $rutaFinal = Join-Path $OUTPUT_DIR $nombreArchivo
        $contador++
    }

    [System.IO.File]::WriteAllText($rutaFinal, $plantilla, (New-Object System.Text.UTF8Encoding($true)))
    Write-OK "Documento de entrega creado:"
    Write-OK "   $rutaFinal"
} catch {
    Write-ERR "Error al crear el documento: $($_.Exception.Message)"
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
Write-Host "   Archivo txt: $nombreArchivo" -ForegroundColor Yellow
Write-Host "   (abrelo y copia TODO el contenido en WhatsApp)"
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Copiar key al portapapeles
try {
    Set-Clipboard -Value $KEY
    Write-INFO "Key copiada al portapapeles"
} catch { }

# Abrir el txt automaticamente (Bloc de notas)
try {
    Start-Process notepad.exe -ArgumentList "`"$rutaFinal`""
    Write-INFO "Abriendo el archivo en el Bloc de notas..."
} catch { }

# Pausa para que la ventana NO se cierre (solo si hay consola interactiva)
if (-not [Console]::IsInputRedirected) {
    Write-Host ""
    Write-Host "Presiona ENTER para cerrar..." -ForegroundColor Cyan
    Read-Host | Out-Null
}
