#!/bin/bash
# =============================================================
#  VPS LICENSE GATE — VALIDADOR DE LICENCIA (Firebase RTDB)
#  -------------------------------------------------------------
#  Este es el CORAZÓN del sistema anti-piratería.
#  Valida una clave de licencia contra Firebase Realtime Database.
#
#  MODELO DE NEGOCIO:
#   - El cliente recibe una key al comprar
#   - Puede instalar en CUANTAS VPS quiera durante 30 días
#   - Pasados los 30 días, la key ya NO instala en VPS nuevas
#   - Los ya instalados siguen recibiendo actualizaciones (git pull)
#
#  SEGURIDAD:
#   - La decisión final la toma Firebase (servidor), no el script
#   - La key es imposible de adivinar (10 chars hex aleatorios)
#   - Las reglas RTDB impiden listar/enumerar todas las keys
#   - Se registra cada activación (IP, hostname, fecha) para trazabilidad
#
#  USO:
#    ./validar-licencia.sh                    # pide la key interactiva
#    ./validar-licencia.sh KEY-XXXXXXXXXX     # valida la key dada
#    LICENCIA_KEY=KEY-XXX ./validar-licencia.sh  # vía variable de entorno
#    ./validar-licencia.sh --test KEY-XXX     # modo prueba (no registra)
# =============================================================

# ================= CONFIGURACIÓN =================
# URL de la Realtime Database (SIN https:// y SIN .json)
FB_BASE="keygenbpt-default-rtdb.firebaseio.com"
# Rama donde viven las licencias
FB_LICENCIAS="licencias_movivip"
# Rama donde se registran las activaciones (trazabilidad)
FB_ACTIVACIONES="activaciones_movivip"
# Archivo local donde se guarda la licencia activa
LICENCIA_FILE="/etc/movivip/licencia.conf"

# ================= COLORES =================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# ================= FUNCIONES =================
log_ok()   { echo -e "${GREEN}[✔]${NC} $1"; }
log_err()  { echo -e "${RED}[✘]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_info() { echo -e "${CYAN}[→]${NC} $1"; }

# Validar formato de key: KEY-XXXXXXXXXX (10 hex)
key_formato_valido() {
    [[ "$1" =~ ^KEY-[0-9A-F]{10}$ ]]
}

# Obtener IP pública
get_ip() {
    local ip
    ip=$(curl -s --max-time 8 ifconfig.me 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -s --max-time 8 api.ipify.org 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo "$ip"
}

# Consultar la licencia en Firebase
# Devuelve 0 = key existe, 1 = key no existe, 2 = error de red
firebase_consulta() {
    local key="$1"
    local url="https://${FB_BASE}/${FB_LICENCIAS}/${key}.json"
    local resp
    resp=$(curl -s --max-time 15 "$url" 2>/dev/null)
    if [[ $? -ne 0 || -z "$resp" ]]; then
        return 2
    fi
    # Si la respuesta es "null" => key no existe
    if [[ "$resp" == "null" ]]; then
        return 1
    fi
    echo "$resp"
    return 0
}

# Extraer campo del JSON (sin jq - compatible con cualquier sistema)
json_get() {
    local json="$1" campo="$2"
    echo "$json" | grep -o "\"${campo}\"[[:space:]]*:[[:space:]]*[^,}]*" | head -n1 | sed "s/\"${campo}\"[[:space:]]*:[[:space:]]*//" | tr -d '"' | tr -d ' '
}

# ================= MAIN =================
main() {
    local KEY="" TEST_MODE=0

    # Parsear argumentos
    if [[ "$1" == "--test" ]]; then
        TEST_MODE=1
        shift
    fi
    KEY="${1:-$LICENCIA_KEY}"

    # Encabezado
    clear 2>/dev/null
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🔑 VALIDACIÓN DE LICENCIA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Pedir key si no viene
    if [[ -z "$KEY" ]]; then
        read -p "Ingresa tu clave de licencia: " KEY
    fi

    # Validar formato
    if ! key_formato_valido "$KEY"; then
        log_err "Formato de clave inválido. Debe ser: KEY-XXXXXXXXXX (10 caracteres hex)"
        echo ""
        log_warn "Ejemplo: KEY-3F8A21C9D4"
        return 1
    fi

    log_info "Consultando servidor de licencias..."
    local resp
    resp=$(firebase_consulta "$KEY")
    local code=$?

    if [[ $code -eq 2 ]]; then
        log_err "No se pudo conectar al servidor de licencias."
        log_err "Verifica la conexión a internet y reintenta."
        return 2
    fi

    if [[ $code -eq 1 ]]; then
        log_err "❌ CLAVE NO VÁLIDA."
        log_err "La clave '$KEY' no existe en el sistema."
        echo ""
        log_warn "💡 Adquiere una licencia válida para instalar este sistema."
        return 1
    fi

    # Parsear respuesta
    local activa expira creada cliente plan
    activa=$(json_get "$resp" "activa")
    expira=$(json_get "$resp" "expira")
    creada=$(json_get "$resp" "creada")
    cliente=$(json_get "$resp" "cliente")
    plan=$(json_get "$resp" "plan")

    log_info "Licencia encontrada: ${cliente:-cliente anónimo} (plan: ${plan:-standard})"

    # Verificar que está activa
    if [[ "$activa" != "true" ]]; then
        log_err "❌ LICENCIA DESACTIVADA."
        log_err "Esta clave fue revocada por el proveedor."
        return 1
    fi

    # Verificar expiración
    local now
    now=$(date +%s)
    if [[ -n "$expira" && "$expira" =~ ^[0-9]+$ && "$now" -gt "$expira" ]]; then
        local expira_humano
        expira_humano=$(date -d "@$expira" '+%Y-%m-%d %H:%M' 2>/dev/null || date -r "$expira" '+%Y-%m-%d %H:%M' 2>/dev/null)
        log_err "❌ LICENCIA EXPIRADA."
        log_err "Esta clave venció el: ${expira_humano:-$expira}"
        echo ""
        log_warn "💡 Renueva tu licencia para seguir instalando en nuevos servidores."
        return 1
    fi

    # Mostrar días restantes
    if [[ -n "$expira" && "$expira" =~ ^[0-9]+$ ]]; then
        local dias_restantes
        dias_restantes=$(( (expira - now) / 86400 ))
        [[ $dias_restantes -lt 0 ]] && dias_restantes=0
        log_ok "Licencia VÁLIDA — ${dias_restantes} día(s) restantes para instalar en nuevos VPS."
    else
        log_ok "Licencia VÁLIDA (sin fecha de expiración)."
    fi

    # Guardar licencia local
    if [[ $TEST_MODE -eq 0 ]]; then
        mkdir -p /etc/movivip 2>/dev/null
        cat > "$LICENCIA_FILE" <<EOF
KEY="$KEY"
ACTIVADA="$(date '+%Y-%m-%d %H:%M:%S')"
EXPIRA="$expira"
PLAN="$plan"
CLIENTE="$cliente"
EOF
        chmod 600 "$LICENCIA_FILE" 2>/dev/null
        log_ok "Licencia guardada en $LICENCIA_FILE"

        # Registrar activación (trazabilidad)
        local ip fecha ts
        ip=$(get_ip)
        fecha=$(date '+%Y-%m-%d %H:%M:%S')
        ts=$(date +%s)
        local host
        host=$(hostname 2>/dev/null || echo "desconocido")
        curl -s --max-time 15 -X PUT \
            "https://${FB_BASE}/${FB_ACTIVACIONES}/${KEY}/${ts}.json" \
            -H "Content-Type: application/json" \
            -d "{\"ip\":\"${ip}\",\"hostname\":\"${host}\",\"fecha\":\"${fecha}\"}" >/dev/null 2>&1
        log_ok "Activación registrada (IP: $ip)"
    else
        log_warn "Modo prueba: no se guardó ni registró la activación."
    fi

    return 0
}

# Ejecutar
main "$@"
exit $?
