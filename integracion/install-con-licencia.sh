#!/bin/bash
# =============================================================
#  INSTALADOR CON VALIDACIÓN DE LICENCIA v5.0
#  -------------------------------------------------------------
#  Wrapper fino: valida licencia → delega a install.sh de MoviVIPNetwork.
#
#  INSTRUCCIONES DE VENTA (dar al cliente):
#    apt update && apt install -y curl
#    bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)
# =============================================================

export DEBIAN_FRONTEND=noninteractive
export TERM="${TERM:-xterm}"

# =============================================================
#  PARTE 0 — REPARACIÓN AUTOMÁTICA DEL SISTEMA
# =============================================================

sistema_apt_danado() {
    fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && return 0
    dpkg --audit >/dev/null 2>&1 && return 0
    apt-get check >/dev/null 2>&1 || return 0
    return 1
}

reparar_apt() {
    echo ""
    echo "🔧 Detectado sistema con apt/dpkg dañado. Reparando automáticamente..."
    echo ""
    local espera=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        [[ $espera -ge 60 ]] && break
        echo "   ...esperando lock de apt (${espera}s)"
        sleep 5
        espera=$((espera + 5))
    done
    if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        for pid in $(fuser /var/lib/dpkg/lock-frontend 2>/dev/null); do
            kill -9 "$pid" 2>/dev/null || true
        done
        sleep 2
        rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock 2>/dev/null || true
    fi
    dpkg --configure -a >/dev/null 2>&1 || true
    apt-get -f install -y >/dev/null 2>&1 || true
    if ! apt-get update -y >/dev/null 2>&1; then
        rm -rf /var/lib/apt/lists/* 2>/dev/null
        apt-get update -y >/dev/null 2>&1 || true
    fi
    echo "   ✅ Sistema reparado."
}

if sistema_apt_danado; then
    reparar_apt
fi

# =============================================================
#  PARTE 1 — GATE DE LICENCIA
# =============================================================

GATE_URL="https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/gate/validar-licencia.sh"
GATE_TMP="/tmp/validar-licencia.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🔑 SISTEMA CON LICENCIA — VALIDACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

command -v curl >/dev/null 2>&1 || apt-get install -y curl >/dev/null 2>&1

echo "Cargando módulo de validación..."
if ! curl -fsSL --max-time 30 "$GATE_URL" -o "$GATE_TMP" 2>/dev/null; then
    echo "❌ No se pudo cargar el módulo de validación."
    exit 1
fi
chmod +x "$GATE_TMP"

bash "$GATE_TMP"
GATE_RESULT=$?

if [[ $GATE_RESULT -ne 0 ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ❌ LICENCIA NO VÁLIDA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   💬 Telegram : @MoviVIP"
    echo "   📱 WhatsApp : +57 311 700 8185"
    echo "   🌐 Web      : https://movivip-network.web.app"
    echo ""
    exit 1
fi

echo ""
echo "✅ LICENCIA VALIDADA — CONTINUANDO INSTALACIÓN..."
echo ""

# =============================================================
#  PARTE 2 — ACTUALIZACIÓN (si ya existe /etc/movivip)
# =============================================================

if [[ -d "/etc/movivip" ]]; then
    echo "🔄 Actualización detectada..."
    if [[ -d "/etc/movivip/.git" ]]; then
        cd /etc/movivip || exit 1
        git reset --hard >/dev/null 2>&1
        git pull origin main >/dev/null 2>&1 || git pull >/dev/null 2>&1
        chmod -R +x /etc/movivip
        echo "✅ Sistema actualizado correctamente."
        echo "💡 Reinicia el menú con: menu"
        exit 0
    else
        cd /
        rm -rf /etc/movivip
    fi
fi

# =============================================================
#  PARTE 3 — INSTALACIÓN NUEVA
#  Descarga install.sh desde MoviVIPNetwork y lo ejecuta.
#  install.sh contiene TODO:
#    - Idioma (10 idiomas)
#    - Paquetes + apt-mark hold
#    - SSL/TLS + HAProxy automático
#    - Optimizador (red + iptables + limpieza segura)
#    - Selector interactivo de protocolos
#    - Configuración del servidor
#    - Git clone + fail2ban + monitoreo + banner
# =============================================================

INSTALL_URL="https://raw.githubusercontent.com/studioanime977/MoviVIPNetwork/main/install.sh"
INSTALL_TMP="/tmp/movivip-install.sh"

echo "📥 Descargando instalador MoviVIP Network v5.0..."
if ! curl -fsSL --max-time 60 "$INSTALL_URL" -o "$INSTALL_TMP" 2>/dev/null; then
    echo "❌ No se pudo descargar el instalador."
    exit 1
fi

chmod +x "$INSTALL_TMP"
sed -i 's/\r$//' "$INSTALL_TMP" 2>/dev/null

echo ""
echo "🚀 Ejecutando instalador completo con selector de protocolos..."
echo ""

bash "$INSTALL_TMP"
INSTALL_EXIT=$?

rm -f "$INSTALL_TMP"

if [[ $INSTALL_EXIT -ne 0 ]]; then
    echo ""
    echo "⚠️  El instalador terminó con código $INSTALL_EXIT"
    exit $INSTALL_EXIT
fi

exit 0
