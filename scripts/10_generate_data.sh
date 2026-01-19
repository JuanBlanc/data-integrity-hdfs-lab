#!/usr/bin/env bash
set -euo pipefail

# TODO: Genera dataset realista (logs e IoT) con tamaño suficiente.
# Recomendación: generar 512MB-2GB totales para observar bloques.

OUT_DIR=${OUT_DIR:-./data_local}
DT=${DT:-$(date +%F)}
mkdir -p "$OUT_DIR/$DT"

echo "[generate] Escribe aquí la generación de:"
echo "  - logs_${DT//-/}.log"
echo "  - iot_${DT//-/}.jsonl"
echo "[generate] Salida en: $OUT_DIR/$DT"

# Pistas:
# - logs: líneas de texto con timestamp, userId, action, status
# - iot: JSON Lines con deviceId, ts, metric, value
# - Para crecer tamaño: bucles, gzip opcional, o dd + plantillas

echo "[generate] TODO completarlo."
