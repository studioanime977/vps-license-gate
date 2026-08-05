# 🔑 VPS License Gate

Sistema de validación de licencia para scripts VPS.

## 🚀 Instalación

```bash
apt update && apt install -y curl
bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)
```

El instalador pedirá tu **key de licencia** → valida contra el servidor → instala el script.

## 📌 Notas

- La key se usa para instalar; los scripts ya instalados no piden key en actualizaciones.
- Cada instalación queda registrada en el servidor.
- Si el sistema presenta errores de apt/dpkg (comunes tras probar otros scripts), el instalador **los repara automáticamente** antes de continuar.

## 🗂️ Estructura pública

```
vps-license-gate/
├── gate/
│   └── validar-licencia.sh      # Módulo de validación (descargado por el instalador)
└── integracion/
    └── install-con-licencia.sh  # Instalador del cliente
```
