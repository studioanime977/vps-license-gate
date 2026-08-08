# 🔑 VPS License Gate

Sistema de validación de licencia para scripts VPS.

## 🚀 Instalación

```bash
apt update && apt install -y curl
bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)
```

El instalador pedirá tu **key de licencia** → valida contra el servidor → instala el script.

## 💬 Contacto

¿Necesitas una licencia o renovar la tuya? Contáctanos:

| Canal | Dato |
|:---|:---|
| 💬 **Telegram** | [@MoviVIP](https://t.me/MoviVIP) |
| 📱 **WhatsApp** | [+57 311 700 8185](https://wa.me/573117008185) |
| 🌐 **Web** | [https://movivip-network.web.app](https://movivip-network.web.app) |
| 📢 **Canal** | [@MoviVIPNetwork](https://t.me/MoviVIPNetwork) |
| 👥 **Grupo** | [@MoviVIPNet](https://t.me/MoviVIPNet) |

## 📌 Notas

### 🛡 Política de licencia (confirmada)
- **NINGÚN plan se desactiva por no pagar la licencia.** El panel y los protocolos siguen funcionando normal SIEMPRE.
- La licencia **solo controla las actualizaciones**:
  - plan **activo** → puede actualizar cuando quiera (él decide si actualizar o no).
  - plan **vencido/sin licencia** → se le **notifica** que hay una actualización disponible, pero **no se descarga**. Renueva para actualizar.
- Cada instalación queda registrada en el servidor (trazabilidad).
- Si el sistema presenta errores de apt/dpkg (comunes tras probar otros scripts), el instalador **los repara automáticamente** antes de continuar.

### 🔄 Flujo de actualización (update.sh)
1. Compara `version.txt` local vs remoto (repo `MoviVIPNetwork`).
2. Si NO hay novedad → "ya tienes la última versión".
3. Si HAY novedad:
   - `validar-licencia.sh --check` (Firebase) decide si el plan está activo.
   - Activo → pregunta al cliente si quiere actualizar ahora.
   - No activo → avisa que hay actualización pero no aplica nada; el panel sigue normal.

## 🗂️ Estructura pública

```
vps-license-gate/
├── gate/
│   └── validar-licencia.sh      # Módulo de validación (--check para update.sh)
└── integracion/
    └── install-con-licencia.sh  # Instalador del cliente
```

> El panel (repo `MoviVIPNetwork`) incluye `update.sh` y `version.txt`; la opción
> `[09] Update` del menú delega en `update.sh` para respetar la política.
