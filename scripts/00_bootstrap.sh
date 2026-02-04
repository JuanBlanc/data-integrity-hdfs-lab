#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[bootstrap] Creando estructura HDFS"
echo "[bootstrap] DT=$DT"
echo "============================================"

# Crear estructura de datos
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /data/logs/raw/dt=$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /data/iot/raw/dt=$DT"

# Crear estructura de backup (Variante A: mismo clúster)
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /backup/logs/raw/dt=$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /backup/iot/raw/dt=$DT"

# Crear estructura de auditoría
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/fsck/$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/inventory/$DT"

echo ""
echo "[bootstrap] Estructura HDFS creada:"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -ls -R /"

echo ""
echo "[bootstrap] Completado."
