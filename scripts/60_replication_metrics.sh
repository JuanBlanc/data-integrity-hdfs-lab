#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
DT_COMPACT=${DT//-/}

echo "============================================"
echo "[metrics] Métricas de replicación y recursos"
echo "[metrics] DT=$DT"
echo "============================================"

# ---------- FASE 1: Docker stats (snapshot de recursos) ----------
echo ""
echo "[metrics] === FASE 1: Captura de recursos (docker stats) ==="
echo ""
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" | tee ./data_local/docker_stats_${DT_COMPACT}.txt
echo ""
echo "[metrics] Docker stats guardado en ./data_local/docker_stats_${DT_COMPACT}.txt"

# Copiar docker stats al contenedor para guardar en HDFS
docker cp ./data_local/docker_stats_${DT_COMPACT}.txt $NN_CONTAINER:/tmp/docker_stats_${DT_COMPACT}.txt
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/metrics/$DT"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/docker_stats_${DT_COMPACT}.txt /audit/metrics/$DT/docker_stats.txt"

# ---------- FASE 2: Espacio actual con replicación por defecto ----------
echo ""
echo "[metrics] === FASE 2: Espacio con replicación actual ==="
echo ""
echo "--- Espacio lógico ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -du -h /data"
echo ""
echo "--- Replicación actual ---"
docker exec -it $NN_CONTAINER bash -lc "hdfs getconf -confKey dfs.replication"

# ---------- FASE 3: Experimento de replicación 1 vs 2 vs 3 ----------
echo ""
echo "[metrics] === FASE 3: Experimento de replicación ==="
echo ""

# Usamos el fichero de logs como muestra para medir impacto
TEST_FILE="/data/logs/raw/dt=$DT/logs_${DT_COMPACT}.log"

# Verificar que el fichero existe
FILE_EXISTS=$(docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -test -f $TEST_FILE && echo yes || echo no" | tr -d '\r\n ')
if [[ "$FILE_EXISTS" != *"yes"* ]]; then
    echo "[metrics] ERROR: No se encuentra $TEST_FILE en HDFS."
    echo "[metrics] Ejecuta primero los scripts 10, 20."
    exit 1
fi

# Obtener tamaño lógico del fichero
LOGICAL_SIZE=$(docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -du -s $TEST_FILE" | awk '{print $1}' | tr -d '\r\n ')
LOGICAL_SIZE_MB=$((LOGICAL_SIZE / 1024 / 1024))
echo "[metrics] Fichero de prueba: $TEST_FILE"
echo "[metrics] Tamaño lógico: ${LOGICAL_SIZE_MB} MB"
echo ""

# CSV de resultados
RESULTS_CSV="/tmp/replication_metrics_${DT}.csv"
docker exec -it $NN_CONTAINER bash -lc "echo 'factor,logical_size_bytes,physical_size_bytes,physical_size_mb,time_setrep_sec' > $RESULTS_CSV"

for REP in 1 2 3; do
    echo "[metrics] --- Cambiando replicación a $REP ---"
    START=$(date +%s)
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -setrep -w $REP $TEST_FILE 2>&1"
    END=$(date +%s)
    ELAPSED=$((END - START))

    PHYSICAL_SIZE=$((LOGICAL_SIZE * REP))
    PHYSICAL_MB=$((PHYSICAL_SIZE / 1024 / 1024))

    echo "[metrics] Replicación $REP: espacio físico = ${PHYSICAL_MB} MB, tiempo setrep = ${ELAPSED}s"

    docker exec -it $NN_CONTAINER bash -lc "echo '${REP},${LOGICAL_SIZE},${PHYSICAL_SIZE},${PHYSICAL_MB},${ELAPSED}' >> $RESULTS_CSV"

    # Verificar estado tras cambiar replicación
    docker exec -it $NN_CONTAINER bash -lc "hdfs fsck $TEST_FILE 2>&1 | tail -5"
    echo ""
done

# Restaurar replicación a 3 (valor por defecto)
echo "[metrics] Restaurando replicación a 3..."
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -setrep -w 3 $TEST_FILE 2>&1"

# Mostrar tabla de resultados
echo ""
echo "============================================"
echo "[metrics] Tabla comparativa de replicación"
echo "============================================"
docker exec -it $NN_CONTAINER bash -lc "cat $RESULTS_CSV"

# Guardar en HDFS
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f $RESULTS_CSV /audit/metrics/$DT/replication_metrics.csv"

# ---------- FASE 4: Resumen de tiempos del pipeline ----------
echo ""
echo "[metrics] === FASE 4: Resumen de tiempos del pipeline ==="
echo ""
echo "Los tiempos de cada fase se muestran en la salida de cada script:"
echo "  - 10_generate_data.sh → tiempo de generación"
echo "  - 20_ingest_hdfs.sh   → tiempo de ingesta (logs + IoT)"
echo "  - 40_backup_copy.sh   → tiempo de copia (logs + IoT)"
echo "  - 30_fsck_audit.sh    → tiempo de auditoría"
echo ""
echo "Registra estos tiempos en docs/evidencias.md y en el notebook."

# Copiar al volumen de notebooks
docker exec -it $NN_CONTAINER bash -lc "
mkdir -p /media/notebooks/audit/metrics/$DT
cp $RESULTS_CSV /media/notebooks/audit/metrics/$DT/replication_metrics.csv
cp /tmp/docker_stats_${DT_COMPACT}.txt /media/notebooks/audit/metrics/$DT/docker_stats.txt
"

# Limpiar temporales
docker exec -it $NN_CONTAINER bash -lc "rm -f $RESULTS_CSV /tmp/docker_stats_${DT_COMPACT}.txt"

echo ""
echo "[metrics] Resultados guardados en /audit/metrics/$DT/"
echo "[metrics] Copia local en /media/notebooks/audit/metrics/$DT/"
echo "[metrics] Completado."
