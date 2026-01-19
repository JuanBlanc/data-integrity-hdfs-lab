#!/usr/bin/env bash
set -euo pipefail

# Variante A (base): copiar dentro del mismo clúster a /backup
# Variante B (avanzada): usar DistCp hacia otro clúster (no incluido en este starter)

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[backup] DT=$DT"

# TODO (Variante A):
# - Copiar /data/.../dt=$DT/ -> /backup/.../dt=$DT/
# - Registrar logs y validar que existen rutas en destino

echo "[backup] TODO completarlo."
