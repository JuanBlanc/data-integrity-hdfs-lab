#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[incident] Simulación de incidente"
echo "[incident] DT=$DT"
echo "============================================"

# ---------- FASE 1: Estado ANTES del incidente ----------
echo ""
echo "[incident] === FASE 1: Estado ANTES del incidente ==="
echo ""
echo "--- DataNodes activos ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfsadmin -report | head -20"

echo ""
echo "--- fsck ANTES del incidente ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations 2>&1 | tee /tmp/fsck_pre_incident_${DT}.txt"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/fsck/$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_pre_incident_${DT}.txt /audit/fsck/$DT/fsck_pre_incident.txt"

# ---------- FASE 2: Simular caída de DataNode ----------
echo ""
echo "[incident] === FASE 2: Simulando caída de un DataNode ==="

# Obtener el nombre de un contenedor DataNode
DN_CONTAINER=$(docker ps --filter "ancestor=profesorbigdata/hadoop-datanode-image-profesor:v1.0" --format "{{.Names}}" | head -1)

if [[ -z "$DN_CONTAINER" ]]; then
    echo "[incident] ERROR: No se encontró ningún contenedor DataNode en ejecución."
    echo "[incident] Asegúrate de haber levantado el clúster con: docker compose up -d --scale dnnm=3"
    exit 1
fi

echo "[incident] Deteniendo DataNode: $DN_CONTAINER"
docker stop $DN_CONTAINER

echo "[incident] DataNode $DN_CONTAINER detenido."
echo "[incident] Esperando 15 segundos para que HDFS detecte la caída..."
sleep 15

# ---------- FASE 3: Evidencia del impacto ----------
echo ""
echo "[incident] === FASE 3: Estado DESPUÉS del incidente ==="
echo ""
echo "--- DataNodes activos (debería faltar uno) ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfsadmin -report | head -20"

echo ""
echo "--- fsck DESPUÉS del incidente ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations 2>&1 | tee /tmp/fsck_post_incident_${DT}.txt"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_post_incident_${DT}.txt /audit/fsck/$DT/fsck_post_incident.txt"

# Resumen del impacto
echo ""
echo "============================================"
echo "[incident] Resumen del impacto"
echo "============================================"
docker exec -it $NN_CONTAINER bash -lc "
PRE=/tmp/fsck_pre_incident_${DT}.txt
POST=/tmp/fsck_post_incident_${DT}.txt
echo 'ANTES del incidente:'
echo '  CORRUPT:          '\$(grep -ci 'CORRUPT' \$PRE 2>/dev/null || echo 0)
echo '  MISSING:          '\$(grep -ci 'MISSING' \$PRE 2>/dev/null || echo 0)
echo '  UNDER_REPLICATED: '\$(grep -ci 'Under replicated' \$PRE 2>/dev/null || echo 0)
echo ''
echo 'DESPUÉS del incidente:'
echo '  CORRUPT:          '\$(grep -ci 'CORRUPT' \$POST 2>/dev/null || echo 0)
echo '  MISSING:          '\$(grep -ci 'MISSING' \$POST 2>/dev/null || echo 0)
echo '  UNDER_REPLICATED: '\$(grep -ci 'Under replicated' \$POST 2>/dev/null || echo 0)
"

# Copiar evidencias a notebooks
docker exec -it $NN_CONTAINER bash -lc "
mkdir -p /media/notebooks/audit/fsck/$DT
cp /tmp/fsck_pre_incident_${DT}.txt /media/notebooks/audit/fsck/$DT/fsck_pre_incident.txt
cp /tmp/fsck_post_incident_${DT}.txt /media/notebooks/audit/fsck/$DT/fsck_post_incident.txt
"

echo ""
echo "[incident] DataNode detenido: $DN_CONTAINER"
echo "[incident] Para recuperar, ejecuta: bash scripts/80_recovery_restore.sh"
echo "[incident] Completado."
