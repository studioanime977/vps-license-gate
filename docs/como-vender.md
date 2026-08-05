# =============================================================
#  MANUAL DEL VENDEDOR — VPS LICENSE GATE
#  Cómo vender, generar keys y gestionar licencias
# =============================================================

## 1. FLUJO DE VENTA

1. El cliente paga (por el medio que uses: transferencia, binance, etc.)
2. Abres PowerShell en tu PC:
   powershell -ExecutionPolicy Bypass -File generador\generador-keys.ps1
3. Ingresas nombre del cliente y días (default 30)
4. La key se copia al portapapeles
5. Le envías al cliente:

   Hola, aquí está tu licencia para el sistema VPS:

   KEY DE LICENCIA:  KEY-XXXXXXXXXX
   VALIDA HASTA:     YYYY-MM-DD HH:MM

   Instalación (en cualquier VPS Ubuntu):
   apt update && apt install -y curl
   bash <(curl -fsSL https://raw.githubusercontent.com/studioanime977/vps-license-gate/main/integracion/install-con-licencia.sh)

   Puedes instalar en TODAS las VPS que quieras durante la vigencia.
   Después de instalado, el sistema seguirá recibiendo actualizaciones de por vida.

## 2. REGLAS DE NEGOCIO

- La key instala en N VPS (sin límite) durante 30 días
- Pasados los 30 días la key NO instala en VPS nuevas
- Los instalados actualizan de por vida (git pull no pide key)
- Si el cliente pide renovar: generas otra key nueva y se la vendes

## 3. VERIFICAR ACTIVACIONES (trazabilidad)

Para ver quién ha instalado qué:

https://keygenbpt-default-rtdb.firebaseio.com/activaciones_movivip.json

Cada instalación guarda: IP, hostname, fecha, key usada.

## 4. REVOCAR UNA LICENCIA (si un cliente incumple)

Poner activa=false en la key:

PUT https://keygenbpt-default-rtdb.firebaseio.com/licencias_movivip/KEY-XXXXXXXXXX.json
Body: {"activa": false, ...resto igual}

O borrar la key entera:
DELETE https://keygenbpt-default-rtdb.firebaseio.com/licencias_movivip/KEY-XXXXXXXXXX.json

## 5. LISTAR TODAS LAS LICENCIAS

https://keygenbpt-default-rtdb.firebaseio.com/licencias_movivip.json

## 6. PREGUNTAS FRECUENTES

### ¿Qué pasa si el cliente cambia la fecha de su VPS?
Nada. La expiración la valida Firebase (server-side), no la fecha local.

### ¿Puede el cliente clonar el repo directamente y saltarse la key?
El instalador oficial siempre pasa por el gate. Un técnico muy avanzado podría
intentar instalar a mano, pero no puede fabricar keys (no existen en Firebase)
ni puede hacer que las keys expiren más tarde (lo controla el servidor).

### ¿Cuánto dura la instalación en sí?
La instalación completa toma ~5-10 minutos (depende del VPS).

### ¿El instalador reinicia el VPS?
Sí, al final de la instalación (10 segundos de espera).

## 7. RECOMENDACIONES

- Guarda el `generador-keys.ps1` en un lugar seguro, NO en GitHub público
- Usa claves de 30 días por defecto (tu modelo de negocio)
- Revisa `activaciones_movivip` periódicamente para detectar abusos
- Si vendes planes distintos, edita el plan en el generador (standard/premium)
