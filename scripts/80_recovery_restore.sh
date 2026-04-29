#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[recovery] Recuperación tras incidente"
echo "[recovery] DT=$DT"
echo "============================================"

# ---------- FASE 1: Reiniciar DataNode caído ----------
echo ""
echo "[recovery] === FASE 1: Reiniciando DataNodes caídos ==="

# Buscar contenedores DataNode detenidos
STOPPED_DNS=$(docker ps -a --filter "ancestor=profesorbigdata/hadoop-datanode-image-profesor:v1.0" --filter "status=exited" --format "{{.Names}}")

if [[ -z "$STOPPED_DNS" ]]; then
    echo "[recovery] No hay DataNodes detenidos. Todos están activos."
else
    for DN in $STOPPED_DNS; do
        echo "[recovery] Reiniciando DataNode: $DN"
        docker start $DN
    done
    echo "[recovery] Esperando 20 segundos para re-registro y re-replicación..."
    sleep 20
fi

# ---------- FASE 2: Verificar re-replicación ----------
echo ""
echo "[recovery] === FASE 2: Verificando estado post-recuperación ==="
echo ""
echo "--- DataNodes activos ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfsadmin -report | head -20"

echo ""
echo "--- fsck post-recuperación ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations 2>&1 | tee /tmp/fsck_recovery_${DT}.txt"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_recovery_${DT}.txt /audit/fsck/$DT/fsck_recovery.txt"

# ---------- FASE 3: Restauración desde backup (si datos dañados) ----------
echo ""
echo "[recovery] === FASE 3: Verificando integridad de datos ==="

CORRUPT_COUNT=$(docker exec -it $NN_CONTAINER bash -lc "grep -ci 'CORRUPT' /tmp/fsck_recovery_${DT}.txt 2>/dev/null || echo 0" | tr -d '\r\n ')

if [[ "$CORRUPT_COUNT" -gt 0 ]]; then
    echo "[recovery] Se detectaron $CORRUPT_COUNT bloques CORRUPT."
    echo "[recovery] Restaurando desde /backup ..."

    # Restaurar logs desde backup
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -rm -r -f /data/logs/raw/dt=$DT"
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /data/logs/raw/dt=$DT"
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -cp /backup/logs/raw/dt=$DT/* /data/logs/raw/dt=$DT/"

    # Restaurar IoT desde backup
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -rm -r -f /data/iot/raw/dt=$DT"
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /data/iot/raw/dt=$DT"
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -cp /backup/iot/raw/dt=$DT/* /data/iot/raw/dt=$DT/"

    echo "[recovery] Restauración desde backup completada."
else
    echo "[recovery] No se detectó corrupción. Re-replicación automática exitosa."
fi

# ---------- FASE 4: Auditoría final ----------
echo ""
echo "[recovery] === FASE 4: Auditoría final ==="
docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations 2>&1 | tee /tmp/fsck_final_${DT}.txt"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_final_${DT}.txt /audit/fsck/$DT/fsck_final.txt"

echo ""
echo "============================================"
echo "[recovery] Resumen final"
echo "============================================"
docker exec -it $NN_CONTAINER bash -lc "
FINAL=/tmp/fsck_final_${DT}.txt
echo 'Estado final:'
echo '  CORRUPT:          '\$(grep -ci 'CORRUPT' \$FINAL 2>/dev/null || echo 0)
echo '  MISSING:          '\$(grep -ci 'MISSING' \$FINAL 2>/dev/null || echo 0)
echo '  UNDER_REPLICATED: '\$(grep -ci 'Under replicated' \$FINAL 2>/dev/null || echo 0)
echo '  HEALTHY:          '\$(grep -c 'HEALTHY' \$FINAL 2>/dev/null || echo 0)
"

# Copiar evidencia al volumen de notebooks
docker exec -it $NN_CONTAINER bash -lc "
mkdir -p /media/notebooks/audit/fsck/$DT
cp /tmp/fsck_recovery_${DT}.txt /media/notebooks/audit/fsck/$DT/fsck_recovery.txt
cp /tmp/fsck_final_${DT}.txt /media/notebooks/audit/fsck/$DT/fsck_final.txt
"

# Limpiar temporales
docker exec -it $NN_CONTAINER bash -lc "rm -f /tmp/fsck_recovery_${DT}.txt /tmp/fsck_final_${DT}.txt"

echo ""
echo "[recovery] Completado."
