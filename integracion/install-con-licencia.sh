#!/bin/bash
# =============================================================
#  INSTALADOR CON VALIDACIÓN DE LICENCIA
#  -------------------------------------------------------------
#  Este es el instalador que el CLIENTE ejecuta.
#  Pide la key -> valida contra Firebase -> si es válida,
#  continúa con la instalación normal del sistema VPS.
#
#  INSTRUCCIONES DE VENTA (dar al cliente):
#    apt update && apt install -y curl
#    bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)
#
#  MODELO: la key instala en TODAS las VPS que quiera durante 30 días.
#  Después de instalado, recibe actualizaciones de por vida.
# =============================================================

# =============================================================
#  PARTE 0 — PREPARACIÓN DEL ENTORNO
#  Evita cuelgues por diálogos de apt y errores de tput/TERM
# =============================================================

export DEBIAN_FRONTEND=noninteractive
export TERM="${TERM:-xterm}"

# =============================================================
#  PARTE 0.5 — REPARACIÓN AUTOMÁTICA DEL SISTEMA
#  -------------------------------------------------------------
#  Blindaje: muchos clientes vienen de OTROS scripts que dejaron
#  el sistema con apt/dpkg dañado. Esto corrige SOLO los errores
#  más comunes SIN tocar la instalación del cliente:
#
#   1. Lock de apt colgado (proceso muerto/huérfano con el lock)
#   2. dpkg a medio configurar (paquetes rotos por instalación cortada)
#   3. Dependencias rotas (apt-get -f install)
#   4. apt colgado pidiendo input (dpkg-preconfigure / debconf)
#   5. Listas de apt corruptas (apt update falla)
# =============================================================

# Detectar si el sistema de paquetes está dañado (rápido si está sano)
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

    # 1. Esperar a que se libere el lock (procesos legítimos terminan solos)
    local espera=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        if [[ $espera -ge 60 ]]; then
            break
        fi
        echo "   ...esperando a que se libere el lock de apt (${espera}s)"
        sleep 5
        espera=$((espera + 5))
    done

    # 2. Si sigue tomado, terminar el proceso colgado y limpiar locks huérfanos
    if fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
        echo "   ⚠️  Lock tomado por un proceso colgado — terminándolo..."
        for pid in $(fuser /var/lib/dpkg/lock-frontend 2>/dev/null); do
            kill -9 "$pid" 2>/dev/null || true
        done
        sleep 2
        rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock 2>/dev/null || true
        echo "   ✅ Lock liberado."
    fi

    # 3. Configurar paquetes pendientes (dpkg a medio instalar)
    echo "   🔧 Configurando paquetes pendientes..."
    dpkg --configure -a >/dev/null 2>&1 || true

    # 4. Reparar dependencias rotas
    echo "   🔧 Corrigiendo dependencias rotas..."
    apt-get -f install -y >/dev/null 2>&1 || true

    # 5. Si apt update falla, limpiar listas corruptas y reintentar
    if ! apt-get update -y >/tmp/movivip-apt-update.log 2>&1; then
        echo "   ⚠️  apt update falló — limpiando listas corruptas..."
        rm -rf /var/lib/apt/lists/* 2>/dev/null
        apt-get update -y >/tmp/movivip-apt-update.log 2>&1 || true
    fi

    echo ""
    echo "   ✅ Sistema de paquetes reparado. Continuando..."
    echo ""
}

# Ejecutar reparación SIEMPRE (el chequeo es instantáneo en sistemas sanos)
if sistema_apt_danado; then
    reparar_apt
fi

# =============================================================
#  PARTE 1 — GATE DE LICENCIA (valida antes de instalar)
# =============================================================

# URL del gate (se descarga en caliente para que siempre sea la última versión)
GATE_URL="https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/gate/validar-licencia.sh"
GATE_TMP="/tmp/validar-licencia.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   🔑 SISTEMA CON LICENCIA — VALIDACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Asegurar curl (si apt estaba roto, ya lo reparó la Parte 0.5)
command -v curl >/dev/null 2>&1 || apt-get install -y curl >/dev/null 2>&1

# Descargar el gate
echo "Cargando módulo de validación..."
if ! curl -fsSL --max-time 30 "$GATE_URL" -o "$GATE_TMP" 2>/dev/null; then
    echo "[✘] No se pudo cargar el módulo de validación. Verifica internet."
    exit 1
fi

chmod +x "$GATE_TMP"

# Ejecutar la validación (pide la key interactivamente)
bash "$GATE_TMP"
GATE_RESULT=$?

if [[ $GATE_RESULT -ne 0 ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ❌ INSTALACIÓN BLOQUEADA — LICENCIA NO VÁLIDA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Este sistema requiere una clave de licencia válida."
    echo ""
    echo "   🔑 Adquiere tu licencia aquí:"
    echo "   ─────────────────────────────────────────"
    echo "   💬 Telegram : @MoviVIP"
    echo "   📱 WhatsApp : +57 311 700 8185"
    echo "   🌐 Web      : https://movivip-network.web.app"
    echo "   📢 Canal    : https://t.me/MoviVIPNetwork"
    echo "   👥 Grupo    : https://t.me/MoviVIPNet"
    echo "   ─────────────────────────────────────────"
    echo ""
    exit 1
fi

echo ""
echo "✅ LICENCIA VALIDADA — CONTINUANDO INSTALACIÓN..."
echo ""

# =============================================================
#  PARTE 2 — INSTALACIÓN NORMAL DEL SISTEMA VPS
#  (copia exacta del install.sh original con pequeñas mejoras)
# =============================================================

if [[ -d "/etc/movivip" ]]; then
    echo " Actualización detectada..."
    if [[ -d "/etc/movivip/.git" ]]; then
        cd /etc/movivip || exit 1
        git reset --hard
        git pull origin main || git pull
        echo " Sistema actualizado correctamente"
        exit 0
    else
        cd /
        rm -rf /etc/movivip
    fi
fi

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "      🛡️ MoviVIP Network 🛡️"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [[ $EUID -ne 0 ]]; then
echo "❌ Necesita root"
exec sudo bash "$0" "$@"
fi

#==============================

# UBUNTU CHECK

#==============================

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
echo "❌ Solo Ubuntu"
exit 1
fi

clear

echo "✔ Sistema Ubuntu detectado"
sleep 1
  #==============================
# INSTALAR PAQUETES BÁSICOS
#==============================

echo "📦 Instalando paquetes básicos..."

apt update -y
apt install -y \
curl \
wget \
git \
unzip \
zip \
tar \
sudo \
nano \
cron \
net-tools \
dnsutils \
lsof \
screen \
jq \
bc \
socat \
openssl \
ca-certificates \
fail2ban \
whois \
rkhunter \
chkrootkit \
lynis

echo "✅ Paquetes instalados."

#==============================
# INSTALAR OPENSSH
#==============================

echo "🔐 Instalando OpenSSH..."

apt install -y openssh-server

systemctl enable ssh
systemctl restart ssh

echo "✅ OpenSSH instalado y activo en el puerto 22."
sleep 2
#==============================

# CONFIG SERVER

#==============================

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "        CONFIGURACIÓN DEL SERVIDOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

read -p "🌐 Dominio Cloudflare: " SERVER_DOMAIN
read -p "🌐 Dominio Cloudfront (Enter si no): " CLOUDFRONT_DOMAIN

# Si no hay input (instalación no interactiva), continuar con valores vacíos
SERVER_DOMAIN="${SERVER_DOMAIN:-}"
CLOUDFRONT_DOMAIN="${CLOUDFRONT_DOMAIN:-}"

SERVER_IP=$(curl -s ifconfig.me)

CLOUDFLARE_STATUS="OFF"
SSL_TUNNEL="OFF"
DOMAIN_IP_MATCH="NO"
PROXY_STATUS="UNKNOWN"
if [[ -n "$SERVER_DOMAIN" ]]; then

echo ""
echo "🔍 Verificando dominio..."

DOMAIN_IP=$(dig +short "$SERVER_DOMAIN" | head -n1)

if [[ "$DOMAIN_IP" == "$SERVER_IP" ]]; then
    DOMAIN_IP_MATCH="YES"
    echo "✅ Dominio apunta al VPS"
    echo "ℹ️ El certificado SSL se podrá instalar desde el menú."

    SSL_TUNNEL="OFF"

else
    echo "❌ Dominio no apunta al VPS"
    SSL_TUNNEL="OFF"
fi

# Cloudflare detect
CF=$(dig +short NS "$SERVER_DOMAIN" | grep cloudflare)

[[ -n "$CF" ]] && CLOUDFLARE_STATUS="ON"

fi
BASE="/etc/movivip"

mkdir -p $BASE/{protocolos,usuarios,sistema,logs}

#==============================

# CONFIG FINAL

#==============================

cat > "$BASE/config.conf" <<EOF
SERVER_DOMAIN="$SERVER_DOMAIN"
CLOUDFRONT_DOMAIN="$CLOUDFRONT_DOMAIN"

CLOUDFLARE_STATUS="$CLOUDFLARE_STATUS"
SSL_TUNNEL="$SSL_TUNNEL"
DOMAIN_IP_MATCH="$DOMAIN_IP_MATCH"
PROXY_STATUS="$PROXY_STATUS"

#==============================
# TRAFICO BASE DEL VPS (bytes)
# Opcional: pon aqui el conteo acumulado que muestra tu proveedor
# para que el panel de consumo muestre el total real del VPS.
# Ej: 6.02 TB = 6020000000000 | 6.6 TB = 6600000000000
#==============================

VPS_TRAFFIC_BASE_RX=0
VPS_TRAFFIC_BASE_TX=0

AUTO_START=OFF

#==============================
# PROTOCOLOS
#==============================

OPENSSH=ON
SYSTEMDNS=OFF
WEBSOCKET=OFF
ZIPVPN=OFF
DROPBEAR=OFF
SSL=OFF

BADVPN=OFF
UDP_CUSTOM=OFF

SLOWDNS=OFF
V2RAY=OFF

OPENVPN=OFF
SQUID=OFF
TROJAN=OFF
V2RAY=OFF
SHADOWSOCKS=OFF
SOCKS5=OFF
WEBMIN=OFF
FAIL2BAN=ON
BBR=OFF

#==============================
# LÍMITES DE CONSUMO DE RED (bytes)
# 0 = sin límite. Configura desde el menú Herramientas → [10]
#==============================

NET_LIMIT_IN=0
NET_LIMIT_OUT=0
EOF
#==============================
# SLOWDNS
#==============================

INSTALL_SLOWDNS="n"

echo ""
echo "ℹ️ SlowDNS no se instala durante la instalación inicial."
echo "💡 Puedes instalarlo y configurarlo más tarde desde el menú."
echo ""

#==============================

# INSTALACIÓN FINAL

#==============================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     🚀 FINALIZANDO INSTALACIÓN"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 2

# permisos

chmod -R 777 $BASE


# comando menu

cat > /usr/local/bin/menu <<EOF
#!/bin/bash
exec bash /etc/movivip/menu.sh
EOF

chmod +x /usr/local/bin/menu

#==============================

# RESUMEN FINAL

#==============================

clear

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "        ✅ INSTALACIÓN COMPLETA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Domain : $SERVER_DOMAIN"
echo "🔐 SSL    : $SSL_TUNNEL"
echo "☁️ CF     : $CLOUDFLARE_STATUS"
echo ""
echo ""
echo "📦 Estado de la instalación:"
echo "   ✅ Paquetes básicos instalados"
echo "   ✅ Sistema preparado correctamente"
echo "   ⚙️ Ningún protocolo fue instalado automáticamente"
echo "   💡 Instala los protocolos desde el menú principal"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📥 Descargando MoviVIP Network..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd /root || exit 1

rm -rf /tmp/multi-script

git clone https://github.com/studioanime977/MoviVIPNetwork.git /tmp/multi-script || exit 1

mkdir -p /etc/movivip

cp -a /tmp/multi-script/. /etc/movivip/

chmod -R +x /etc/movivip

rm -rf /tmp/multi-script

if [[ ! -f /etc/movivip/menu.sh ]]; then
    echo "❌ ERROR: menu.sh no fue instalado"
    exit 1
fi

#==============================
# BOT SEGÚN PLAN — la key define qué se entrega
#   BRONCE    -> solo script multi-protocolo (sin bot)
#   PREMIUM+  -> script + bot del cliente (paquete en /root/movivip_bots)
#==============================

LICENCIA_CONF="/etc/movivip/licencia.conf"
PLAN_KEY="bronce"

if [[ -f "$LICENCIA_CONF" ]]; then
    source "$LICENCIA_CONF"
    PLAN_KEY="${PLAN:-bronce}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     🤖 BOT SEGÚN PLAN: $PLAN_KEY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "${PLAN_KEY,,}" in
    bronce)
        echo "   📦 Tu plan BRONCE incluye SOLO el script multi-protocolo."
        echo "   ✅ Todos los protocolos VPN (SSH, Dropbear, SSL, UDP, Xray...)"
        echo "   🚫 El bot admin/user es EXCLUSIVO de los planes PREMIUM+."
        echo ""
        echo "   💡 Para subir de plan, contacta a tu proveedor."
        ;;
    premium|platino|vitalicio)
        echo "   ✅ Tu plan $PLAN_KEY incluye script + BOT de administración."
        echo ""
        # El bot se descarga desde GitHub según el plan y el cliente de la key
        # (paquete generado por el vendedor con generar-bot-cliente.ps1 y
        #  publicado en studioanime977/movivip-bots/<cliente>/).
        if [[ -f /etc/movivip/protocolos/bot.sh ]]; then
            echo "   🚀 Instalando bot desde el repo de entregas (plan $PLAN_KEY)..."
            bash /etc/movivip/protocolos/bot.sh --install
            echo ""
            if [[ -d /root/movivip_bots ]]; then
                echo "   ✅ Bot instalado. Actívalo/configúralo desde el menú:"
                echo "      menu → [10] 🤖 Bot Admin"
                echo "      (el bot SOLO crea cuentas SSH y entrega la plantilla de acceso)"
            else
                echo "   ⚠️  El paquete del bot para tu licencia aún no está publicado."
                echo "   👉 Contacta a tu proveedor para que genere tu bot."
            fi
        else
            echo "   ⚠️  bot.sh no encontrado. Instala el bot más tarde desde:"
            echo "      menu → [10] 🤖 Bot Admin"
        fi
        ;;
    *)
        echo "   ⚠️  Plan desconocido ('$PLAN_KEY'). Se entrega solo el script."
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#==============================
# CONFIGURAR FAIL2BAN (seguridad)
#==============================

echo "🛡️ Configurando fail2ban..."

# Modo --install = no interactivo (sin esperar input del usuario)
# timeout = protección extra contra cualquier cuelgue futuro
if [[ -f /etc/movivip/herramientas/fail2ban.sh ]]; then
    timeout 120 bash /etc/movivip/herramientas/fail2ban.sh --install >/dev/null 2>&1
fi

timeout 30 systemctl enable fail2ban >/dev/null 2>&1 || true
timeout 30 systemctl restart fail2ban >/dev/null 2>&1 || true

echo "✅ Fail2ban configurado."

#==============================
# CONSUMO DE RED — cron (base de datos vacía)
#==============================

echo "📊 Activando monitoreo de consumo de red..."

if [[ -f /etc/movivip/herramientas/network_snapshot.sh ]]; then
    chmod +x /etc/movivip/herramientas/network_snapshot.sh
    bash /etc/movivip/herramientas/network_snapshot.sh >/dev/null 2>&1

    # Cron: snapshot cada minuto (persistente)
    if ! crontab -l 2>/dev/null | grep -q "network_snapshot.sh"; then
        (crontab -l 2>/dev/null; echo "* * * * * bash /etc/movivip/herramientas/network_snapshot.sh >/dev/null 2>&1") | crontab -
    fi

    # Systemd timer opcional para arranque (persistencia ante reinicios)
    if [[ ! -f /etc/systemd/system/movivip-net-state.service ]]; then
        cat > /etc/systemd/system/movivip-net-state.service <<'EOF'
[Unit]
Description=MoviVIP Network State - consumo de red
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/movivip/herramientas/network_snapshot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable movivip-net-state.service >/dev/null 2>&1
    fi
fi

echo "✅ Monitoreo de consumo activado."

#==============================
# CONSUMO POR USUARIO — cron (online.sh --quiet)
#==============================

echo "👁️ Activando monitoreo de consumo por usuario..."

if [[ -f /etc/movivip/usuarios/online.sh ]]; then
    chmod +x /etc/movivip/usuarios/online.sh
    bash /etc/movivip/usuarios/online.sh --quiet >/dev/null 2>&1

    # Cron: acumular consumo cada 5 minutos (persistente)
    if ! crontab -l 2>/dev/null | grep -q "usuarios/online.sh --quiet"; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * bash /etc/movivip/usuarios/online.sh --quiet >/dev/null 2>&1") | crontab -
    fi
fi

echo "✅ Monitoreo de consumo por usuario activado."

cat > /etc/profile.d/MoviVIP-banner.sh << 'EOF'
#!/bin/bash

[[ $- != *i* ]] && return

clear

SERVER=$(hostname)
DOMAIN="-"

if [[ -f /etc/movivip/config.conf ]]; then
    source /etc/movivip/config.conf
    DOMAIN="${SERVER_DOMAIN:-"-"}"
fi
UPTIME=$(uptime -p | sed 's/up //')
FECHA=$(date +"%d-%m-%Y")
HORA=$(date +"%H:%M:%S")

# Centrado automático
center() {
    local text="$1"
    local cols
    cols=$(tput cols 2>/dev/null || echo 80)
    local len=$(( ${#text} ))
    local pad=$(( (cols - len) / 2 ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%${pad}s" ""
    echo "$text"
}

center "=============================================================="
center ""
center " __  __       _ _   _   _      ____            _       _   "
center "|  \/  |_   _| | |_(_) | |    / ___|  ___ _ __(_)_ __ | |_ "
center "| |\/| | | | | | __| | | |    \___ \ / __| '__| | '_ \| __|"
center "| |  | | |_| | | |_| | | |___  ___) | (__| |  | | |_) | |_ "
center "|_|  |_|\__,_|_|\__|_| |_____| |____/ \___|_|  |_| .__/ \__|"
center "                                                 |_|       "
center ""
center "🚀 MOVIVIP NETWORK — PREMIUM 🚀"
center ""
center "Servidor : $SERVER"
center "Dominio  : $DOMAIN"
center "Uptime   : $UPTIME"
center "Fecha    : $FECHA"
center "Hora     : $HORA"
center ""
center "=============================================================="

if [[ $EUID -ne 0 ]]; then
    center "👤 Usuario : $(whoami)"
    center "🔒 No eres root."
    center "👉 Ejecuta: sudo -i"
else
    center "👑 Usuario : root"
    center "👉 Escribe: menu"
fi

center ""
center "✨ Gracias por usar nuestros servicios ✨"
center "🛡 SISTEMA PROTEGIDO POR MOVIVIP NETWORK"
center ""
EOF

chmod +x /etc/profile.d/MoviVIP-banner.sh

#==============================
# BANNER DE LOGIN SSH (issue.net) — EN BLANCO por defecto
# El usuario puede crear su propio banner desde:
#   Usuarios → [06] 📢 Banner SSH / Dropbear
#==============================

: > /etc/issue.net

# Desactivar Banner en sshd (mantener login limpio)
if grep -q "^Banner" /etc/ssh/sshd_config 2>/dev/null; then
    sed -i 's|^Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config
else
    echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
fi

if [[ -f /etc/default/dropbear ]] && ! grep -q "DROPBEAR_BANNER" /etc/default/dropbear; then
    echo 'DROPBEAR_BANNER="/etc/issue.net"' >> /etc/default/dropbear
fi

systemctl restart ssh sshd 2>/dev/null
systemctl restart dropbear dropbear_custom 2>/dev/null

echo "✅ Banner de login en blanco (configúralo desde Usuarios → [06])."

#==============================
# RED EXTREMA — BBR + FQ + MTU 1470 + buffers 64MB
# Óptimo para túneles de juegos con alta concurrencia.
# TCP BBR reduce la latencia y maximiza el throughput;
# los buffers de 64MB evitan pérdida de paquetes en ráfagas.
#==============================

cat >/etc/sysctl.d/99-MoviVIP.conf <<'EOF'
# ============ MoviVIP Network — RED EXTREMA ============
# Congestión BBR (TCP) + cola FQ
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Buffers de red 64MB
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=87380
net.core.wmem_default=87380
net.ipv4.tcp_rmem=4096 87380 67108864
net.ipv4.tcp_wmem=4096 87380 67108864
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_slow_start_after_idle=0

# Colas / conexiones masivas
net.core.somaxconn=4096
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_fin_timeout=15
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65000
net.ipv4.tcp_timestamps=1

# Memoria virtual — prioriza rendimiento
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=2

# Límites
fs.file-max=2097152
EOF

sysctl --system >/dev/null 2>&1
ulimit -n 1048576 2>/dev/null

# MTU 1470 en la interfaz activa (óptimo para juegos/túneles)
IFACE_NET=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')
[[ -z "$IFACE_NET" ]] && IFACE_NET=$(ls /sys/class/net | grep -E '^(eth|ens|enp)' | head -n1)
ip link set dev "${IFACE_NET:-eth0}" mtu 1470 2>/dev/null

echo "✅ Red extrema: BBR + FQ + MTU 1470 + buffers 64MB."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ MoviVIP Network instalado."
echo "🔄 El servidor se reiniciará en 10 segundos..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 10

reboot
