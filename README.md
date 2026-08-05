# 🔑 VPS LICENSE GATE

Sistema de **validación de licencia con Firebase** para scripts VPS.

## 📦 Modelo de negocio

| Regla | Detalle |
|-------|---------|
| El cliente compra → recibe una **key** | Ej: `KEY-3F8A21C9D4` |
| Con esa key instala en **TODAS las VPS que quiera** | Sin límite de IPs ni instalaciones |
| La key es válida **30 días** (desde que se genera) | Después ya NO instala en VPS nuevas |
| Los ya instalados reciben **actualizaciones de por vida** | `git pull` / `update.sh` NO piden key |

## 🛡️ Seguridad (7 capas)

1. **La decisión la toma Firebase (servidor)**, no el script
2. Keys **imposibles de adivinar**: `KEY-XXXXXXXXXX` (10 hex = 1 billón de combos)
3. **Reglas RTDB** impiden listar/enumerar todas las keys (solo lectura de key exacta)
4. **Expiración server-side**: aunque el cliente cambie su fecha local, Firebase manda
5. **Trazabilidad**: cada instalación se registra (IP, hostname, fecha)
6. **Multi-instalación controlada**: el modelo de negocio permite N VPS por key
7. **El script no contiene secretos**: solo la URL pública de la RTDB

## 🔧 Auto-reparación (clientes con sistema dañado)

Muchos clientes llegan **después de probar otros scripts** que dejaron el sistema con apt/dpkg dañado. El instalador **detecta y repara automáticamente** sin que el cliente haga nada:

| Problema del sistema | Qué hace el instalador |
|----------------------|------------------------|
| Lock de apt tomado por proceso colgado/huérfano | Espera 60s → lo mata → libera el lock |
| Paquetes a medio configurar (instalación cortada) | `dpkg --configure -a` automático |
| Dependencias rotas | `apt-get -f install -y` automático |
| apt colgado pidiendo input (`dpkg-preconfigure`) | `DEBIAN_FRONTEND=noninteractive` |
| Listas de apt corruptas (`apt update` falla) | Limpia listas y reintenta |

> ✅ Verificado en pruebas reales con lock huérfano y dpkg roto simulados: el instalador repara y continúa sin intervención del usuario.

## 🚀 Uso para el cliente

```bash
apt update && apt install -y curl
bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)
```

El instalador pedirá la key → valida contra Firebase → instala.

## 🗂️ Estructura

```
vps-license-gate/
├── gate/
│   └── validar-licencia.sh      # ★ Módulo de validación (se ejecuta al instalar)
├── generador/
│   └── generador-keys.ps1       # ★ Herramienta del VENDEDOR (privada, no subir)
├── reglas/
│   └── firebase-rules.json      # Reglas de seguridad RTDB
├── integracion/
│   └── install-con-licencia.sh  # Instalador del cliente con gate integrado
└── docs/
    └── como-vender.md           # Manual del vendedor
```

## 🛠️ Para el vendedor (generar una key)

En tu PC (Windows):

```powershell
powershell -ExecutionPolicy Bypass -File generador\generador-keys.ps1
```

1. Escribe el nombre del cliente
2. Escribe los días de validez (default 30)
3. La key se sube sola a Firebase y se copia al portapapeles

> ⚠️ **`generador/config-generador.ps1` NO se sube a GitHub.** Es solo tuyo.

## 🔒 Aplicar reglas de seguridad en Firebase

1. Entra a la consola Firebase → tu proyecto → **Realtime Database**
2. Pestaña **Reglas**
3. Pega el contenido de `reglas/firebase-rules.json`
4. **Publicar**

## 📄 Licencia

Este sistema es propiedad del vendedor. La infraestructura del gate es parte del producto comercial.
