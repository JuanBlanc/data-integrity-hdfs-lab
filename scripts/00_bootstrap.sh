#!/usr/bin/env bash
set -euo pipefail

# TODO: Ajusta el nombre del contenedor namenode si difiere
NN_CONTAINER=${NN_CONTAINER:-namenode}

# Fecha de trabajo (dt=YYYY-MM-DD). Por defecto hoy.
DT=${DT:-$(date +%F)}

echo "[bootstrap] DT=$DT"

# TODO: Crea la estructura HDFS base:
#   /data/logs/raw/dt=$DT/
#   /data/iot/raw/dt=$DT/
#   /backup/... (si Variante A)
#   /audit/fsck/$DT/
#   /audit/inventory/$DT/
# Pista:
#   docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p ..."

echo "[bootstrap] TODO completarlo."
