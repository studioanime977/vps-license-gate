✨ SISTEMA VPS PREMIUM — MoviVIP Network
🔑 Tu clave de licencia (personal e intransferible):

    KEY: {{KEY}}
    ⏳ Validez para INSTALAR: {{INICIO}} → {{FIN}} ({{DIAS}} días)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✨ Características

Protocolos VPN (12)

Protocolo          | Descripción
OpenSSH            | Servidor SSH estándar
Dropbear           | SSH ligero de alto rendimiento
SSL/TLS            | Túnel SSL seguro
BadVPN UDP         | Tunnel UDP GameMode
UDP Custom         | Protocolo UDP personalizado
V2Ray / Xray       | Proxy avanzado con múltiples transports
SlowDNS            | DNS tunneling
ZIPVPN             | VPN comprimida
System DNS         | DNS del sistema
WebSocket          | Túnel WebSocket
Check User         | Verificación de usuarios
Online App         | App en línea

Herramientas (15)

🔥 Firewall inteligente por protocolo
🛡 Fail2ban (3 intentos fallidos = ban 1h, recidiva = 1 semana)
🔍 Auditoría completa (rkhunter + chkrootkit + lynis)
🚫 Bloqueo de anuncios
🚫 Bloqueo de torrents
⚡️ Optimización de red extrema (BBR + FQ + MTU 1470 + buffers 64MB)
🌐 Speedtest integrado
📊 Consumo de red en tiempo real + acumulado + límites configurables
🔄 Snapshots automáticos (cron + systemd)
🖥 Información completa del VPS
🔑 Cambio de contraseña root

Gestión de Usuarios (10 módulos)

➕ Crear usuarios con expiración
🗑 Eliminar / bloquear / editar
📋 Listar con estado
👁 Usuarios en línea en tiempo real
🎨 Banners personalizados por usuario
💾 Backup y restauración
📜 Logs completos de conexiones

🚀 Instalación

Requisitos
VPS con Ubuntu 22.04 o Ubuntu 24.04 (x86_64/AMD64)
Acceso root
1 GB RAM mínimo recomendado

Paso 1 — Instalar curl
apt update && apt install -y curl

Paso 2 — Ejecutar el instalador con tu key
LICENCIA_KEY={{KEY}} bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)

(También puedes ejecutarlo sin la key en el comando: el instalador te la pedirá al inicio)

⚠️ NOTA IMPORTANTE: Tu key permite instalar en TODAS las VPS que quieras durante {{DIAS}} días desde su activación ({{INICIO}} → {{FIN}}). Pasada esa fecha, la key ya no instala en VPS nuevas. Los servidores que ya hayas instalado siguen recibiendo actualizaciones de por vida, sin pedir key.

Acceso al panel
menu

🔧 Uso

Al ejecutar menu verás el panel tipo dashboard con:
Protocolos — instalar/configurar cada protocolo VPN
Herramientas — firewall, auditoría, optimización, bloqueo, speedtest
Usuarios — gestión completa de cuentas
Información — estado del VPS en tiempo real
Seguridad — fail2ban, rootkits, hardening

Configurar límites de consumo
Herramientas → Consumo de Red → Configurar límites (GB)

Actualizar
LICENCIA_KEY={{KEY}} bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)

🛡 Seguridad Incluida

Fail2ban: protege SSH y Dropbear contra fuerza bruta
Rkhunter: detecta rootkits y binarios alterados
Chkrootkit: detecta rootkits conocidos
Lynis: auditoría de hardening con índice de seguridad
Firewall: reglas por protocolo, persistencia automática
Monitoreo: snapshot cada minuto (cron + systemd)
Reparación automática: si tu VPS quedó dañado por otros scripts, el instalador lo repara solo

📄 Licencia

Licencia Comercial de Uso Único
Este software se entrega bajo licencia comercial de uso único para el cliente comprador. Queda prohibida la redistribución, reventa o compartición del código fuente sin autorización escrita del vendedor.

✅ Uso en servidores propios del cliente: permitido
✅ Modificaciones internas del cliente: permitido
❌ Redistribución o reventa: prohibido
❌ Publicación pública del código: prohibido

© 2026. Todos los derechos reservados. Entrega comercial — uso único licenciado.
