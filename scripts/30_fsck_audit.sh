#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "[fsck] DT=$DT"

# TODO:
# - Ejecutar fsck sobre /data (y /backup si existe)
# - Guardar salida en /audit/fsck/$DT/
# - Generar resumen (txt o csv) con conteos de:
#   CORRUPT, MISSING, Under replicated

# Pista:
# docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations | tee /tmp/fsck_data.txt"
# docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_data.txt /audit/fsck/$DT/fsck_data.txt"

echo "[fsck] TODO completarlo."
