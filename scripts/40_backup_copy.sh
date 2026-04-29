#!/usr/bin/env bash
set -euo pipefail

# Variante A (base): copiar dentro del mismo clúster a /backup

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[backup] Copia de datos a /backup (Variante A)"
echo "[backup] DT=$DT"
echo "============================================"

# Crear directorios de backup si no existen
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /backup/logs/raw/dt=$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /backup/iot/raw/dt=$DT"

# Copiar logs
echo "[backup] Copiando /data/logs/raw/dt=$DT/ -> /backup/logs/raw/dt=$DT/ ..."
START_LOGS=$(date +%s)
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -cp -f /data/logs/raw/dt=$DT/* /backup/logs/raw/dt=$DT/"
END_LOGS=$(date +%s)
echo "[backup] Logs copiados en $((END_LOGS - START_LOGS)) segundos."

# Copiar IoT
echo "[backup] Copiando /data/iot/raw/dt=$DT/ -> /backup/iot/raw/dt=$DT/ ..."
START_IOT=$(date +%s)
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -cp -f /data/iot/raw/dt=$DT/* /backup/iot/raw/dt=$DT/"
END_IOT=$(date +%s)
echo "[backup] IoT copiado en $((END_IOT - START_IOT)) segundos."

# Verificar que los ficheros existen en destino
echo ""
echo "============================================"
echo "[backup] Verificación de backup"
echo "============================================"
echo ""
echo "--- Contenido de /backup ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -ls -R /backup"
echo ""
echo "--- Tamaños en /backup ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -du -h /backup"

echo ""
echo "[backup] Tiempo total copia: $((END_IOT - START_LOGS)) segundos."
echo "[backup] Completado."
