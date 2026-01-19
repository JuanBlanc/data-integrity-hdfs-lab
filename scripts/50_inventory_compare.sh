#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[inventory] DT=$DT"

# TODO:
# - Generar inventario origen (/data) y destino (/backup) del día DT
# - Comparar (missing, size mismatch)
# - Guardar resultados en /audit/inventory/$DT/

# Pistas:
# - hdfs dfs -ls -R
# - hdfs dfs -stat '%n,%b,%y' <path>

echo "[inventory] TODO completarlo."
