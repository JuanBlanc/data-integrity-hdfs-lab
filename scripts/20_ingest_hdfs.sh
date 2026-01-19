#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
LOCAL_DIR=${LOCAL_DIR:-./data_local/$DT}

echo "[ingest] DT=$DT"
echo "[ingest] Local dir=$LOCAL_DIR"

# TODO:
# 1) Subir a HDFS en:
#    /data/logs/raw/dt=$DT/
#    /data/iot/raw/dt=$DT/
# 2) Mostrar evidencias con -ls y -du

# Pista:
# docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f ..."

echo "[ingest] TODO completarlo."
