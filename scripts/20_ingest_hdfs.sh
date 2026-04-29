#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
DT_COMPACT=${DT//-/}
LOCAL_DIR=${LOCAL_DIR:-./data_local/$DT}

echo "============================================"
echo "[ingest] Ingesta de datos en HDFS"
echo "[ingest] DT=$DT"
echo "[ingest] Local dir=$LOCAL_DIR"
echo "============================================"

# Verificar que los ficheros locales existen
LOG_FILE="$LOCAL_DIR/logs_${DT_COMPACT}.log"
IOT_FILE="$LOCAL_DIR/iot_${DT_COMPACT}.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[ingest] ERROR: No se encuentra $LOG_FILE. Ejecuta primero 10_generate_data.sh"
    exit 1
fi
if [[ ! -f "$IOT_FILE" ]]; then
    echo "[ingest] ERROR: No se encuentra $IOT_FILE. Ejecuta primero 10_generate_data.sh"
    exit 1
fi

# Copiar ficheros al contenedor NameNode
echo "[ingest] Copiando ficheros al contenedor..."
docker cp "$LOG_FILE" $NN_CONTAINER:/tmp/logs_${DT_COMPACT}.log
docker cp "$IOT_FILE" $NN_CONTAINER:/tmp/iot_${DT_COMPACT}.jsonl

# Subir logs a HDFS
echo "[ingest] Subiendo logs a /data/logs/raw/dt=$DT/ ..."
START_LOG=$(date +%s)
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/logs_${DT_COMPACT}.log /data/logs/raw/dt=$DT/"
END_LOG=$(date +%s)
echo "[ingest] Logs subidos en $((END_LOG - START_LOG)) segundos."

# Subir IoT a HDFS
echo "[ingest] Subiendo IoT a /data/iot/raw/dt=$DT/ ..."
START_IOT=$(date +%s)
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/iot_${DT_COMPACT}.jsonl /data/iot/raw/dt=$DT/"
END_IOT=$(date +%s)
echo "[ingest] IoT subido en $((END_IOT - START_IOT)) segundos."

# Limpiar temporales del contenedor (como root para evitar problemas de permisos)
docker exec -u root $NN_CONTAINER rm -f /tmp/logs_${DT_COMPACT}.log /tmp/iot_${DT_COMPACT}.jsonl

# Evidencias
echo ""
echo "============================================"
echo "[ingest] Evidencias"
echo "============================================"
echo ""
echo "--- hdfs dfs -ls -R /data ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -ls -R /data"
echo ""
echo "--- hdfs dfs -du -h /data ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -du -h /data"

echo ""
echo "[ingest] Tiempo total ingesta: $((END_IOT - START_LOG)) segundos."
echo "[ingest] Completado."
