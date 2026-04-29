#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[fsck] Auditoría de integridad HDFS"
echo "[fsck] DT=$DT"
echo "============================================"

# Crear directorio de auditoría si no existe
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/fsck/$DT"

# Auditoría sobre /data
echo "[fsck] Ejecutando fsck sobre /data ..."
docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /data -files -blocks -locations 2>&1 | tee /tmp/fsck_data_${DT}.txt"

echo ""
echo "[fsck] Guardando resultado en HDFS /audit/fsck/$DT/fsck_data.txt ..."
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_data_${DT}.txt /audit/fsck/$DT/fsck_data.txt"

# Auditoría sobre /backup (si existe)
BACKUP_EXISTS=$(docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -test -d /backup && echo yes || echo no" | tr -d '\r')
if [[ "$BACKUP_EXISTS" == *"yes"* ]]; then
    echo ""
    echo "[fsck] Ejecutando fsck sobre /backup ..."
    docker exec -it $NN_CONTAINER bash -lc "hdfs fsck /backup -files -blocks -locations 2>&1 | tee /tmp/fsck_backup_${DT}.txt"
    docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_backup_${DT}.txt /audit/fsck/$DT/fsck_backup.txt"
else
    echo "[fsck] /backup no existe, omitiendo auditoría de backup."
fi

# Generar resumen con conteos
echo ""
echo "============================================"
echo "[fsck] Generando resumen de auditoría"
echo "============================================"

docker exec -it $NN_CONTAINER bash -lc "
FSCK_FILE=/tmp/fsck_data_${DT}.txt
CORRUPT=\$(grep 'Corrupt blocks:' \$FSCK_FILE 2>/dev/null | awk '{sum+=\$NF} END {print sum+0}')
MISSING=\$(grep 'Missing blocks:' \$FSCK_FILE 2>/dev/null | awk '{sum+=\$NF} END {print sum+0}')
UNDER_REP=\$(grep 'Under-replicated blocks:' \$FSCK_FILE 2>/dev/null | awk '{sum+=\$NF} END {print sum+0}')
HEALTHY=\$(grep -c 'HEALTHY' \$FSCK_FILE 2>/dev/null || echo 0)
TOTAL_SIZE=\$(grep 'Total size:' \$FSCK_FILE 2>/dev/null || echo 'N/A')
TOTAL_FILES=\$(grep 'Total files:' \$FSCK_FILE 2>/dev/null || echo 'N/A')
TOTAL_BLOCKS=\$(grep 'Total blocks' \$FSCK_FILE 2>/dev/null || echo 'N/A')

echo 'date,CORRUPT,MISSING,UNDER_REPLICATED,HEALTHY' > /tmp/fsck_summary_${DT}.csv
echo '${DT},'\$CORRUPT','\$MISSING','\$UNDER_REP','\$HEALTHY >> /tmp/fsck_summary_${DT}.csv

echo '========== RESUMEN FSCK =========='
echo 'Fecha:             ${DT}'
echo 'CORRUPT:          '\$CORRUPT
echo 'MISSING:          '\$MISSING
echo 'UNDER_REPLICATED: '\$UNDER_REP
echo 'HEALTHY:          '\$HEALTHY
echo \$TOTAL_SIZE
echo \$TOTAL_FILES
echo \$TOTAL_BLOCKS
echo '=================================='
"

docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -put -f /tmp/fsck_summary_${DT}.csv /audit/fsck/$DT/fsck_summary.csv"

# Copiar auditoría al volumen de notebooks para Jupyter
docker exec -it $NN_CONTAINER bash -lc "mkdir -p /media/notebooks/audit/fsck/$DT"
docker exec -it $NN_CONTAINER bash -lc "cp /tmp/fsck_data_${DT}.txt /media/notebooks/audit/fsck/$DT/fsck_data.txt"
docker exec -it $NN_CONTAINER bash -lc "cp /tmp/fsck_summary_${DT}.csv /media/notebooks/audit/fsck/$DT/fsck_summary.csv"

# Limpiar temporales
docker exec -it $NN_CONTAINER bash -lc "rm -f /tmp/fsck_data_${DT}.txt /tmp/fsck_backup_${DT}.txt /tmp/fsck_summary_${DT}.csv"

echo ""
echo "[fsck] Auditoría guardada en /audit/fsck/$DT/"
echo "[fsck] Copia local en /media/notebooks/audit/fsck/$DT/ (accesible desde Jupyter)"
echo "[fsck] Completado."
