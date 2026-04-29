#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}

echo "============================================"
echo "[inventory] Validación de backup por inventario"
echo "[inventory] DT=$DT"
echo "============================================"

# Crear directorio de auditoría de inventario
docker exec -it $NN_CONTAINER bash -lc "hdfs dfs -mkdir -p /audit/inventory/$DT"

# Generar inventario estructurado de origen (/data)
echo "[inventory] Generando inventario de /data ..."
docker exec -it $NN_CONTAINER bash -lc "
echo 'name,size,modification_date' > /tmp/inventory_source_${DT}.csv
# Logs
for f in \$(hdfs dfs -ls /data/logs/raw/dt=$DT/ 2>/dev/null | awk '{print \$NF}' | grep -v '^$'); do
    hdfs dfs -stat '%n,%b,%y' \$f >> /tmp/inventory_source_${DT}.csv
done
# IoT
for f in \$(hdfs dfs -ls /data/iot/raw/dt=$DT/ 2>/dev/null | awk '{print \$NF}' | grep -v '^$'); do
    hdfs dfs -stat '%n,%b,%y' \$f >> /tmp/inventory_source_${DT}.csv
done
echo '--- Inventario ORIGEN (/data) ---'
cat /tmp/inventory_source_${DT}.csv
"

# Generar inventario estructurado de destino (/backup)
echo ""
echo "[inventory] Generando inventario de /backup ..."
docker exec -it $NN_CONTAINER bash -lc "
echo 'name,size,modification_date' > /tmp/inventory_backup_${DT}.csv
# Logs
for f in \$(hdfs dfs -ls /backup/logs/raw/dt=$DT/ 2>/dev/null | awk '{print \$NF}' | grep -v '^$'); do
    hdfs dfs -stat '%n,%b,%y' \$f >> /tmp/inventory_backup_${DT}.csv
done
# IoT
for f in \$(hdfs dfs -ls /backup/iot/raw/dt=$DT/ 2>/dev/null | awk '{print \$NF}' | grep -v '^$'); do
    hdfs dfs -stat '%n,%b,%y' \$f >> /tmp/inventory_backup_${DT}.csv
done
echo '--- Inventario DESTINO (/backup) ---'
cat /tmp/inventory_backup_${DT}.csv
"

# Comparar inventarios
echo ""
echo "============================================"
echo "[inventory] Comparación de inventarios"
echo "============================================"
docker exec -it $NN_CONTAINER bash -lc "
SOURCE=/tmp/inventory_source_${DT}.csv
BACKUP=/tmp/inventory_backup_${DT}.csv
REPORT=/tmp/inventory_report_${DT}.txt

echo '========== INFORME DE COMPARACIÓN ==========' > \$REPORT
echo 'Fecha: ${DT}' >> \$REPORT
echo '' >> \$REPORT

# Contar ficheros (sin cabecera)
SRC_COUNT=\$(tail -n +2 \$SOURCE | wc -l)
BAK_COUNT=\$(tail -n +2 \$BACKUP | wc -l)
echo \"Ficheros en origen:  \$SRC_COUNT\" >> \$REPORT
echo \"Ficheros en backup:  \$BAK_COUNT\" >> \$REPORT
echo '' >> \$REPORT

# Comparar por nombre y tamaño
MISSING=0
MISMATCH=0
MATCH=0

while IFS=',' read -r NAME SIZE MOD; do
    [ \"\$NAME\" = 'name' ] && continue
    BAK_LINE=\$(grep \"^\$NAME,\" \$BACKUP 2>/dev/null || true)
    if [ -z \"\$BAK_LINE\" ]; then
        echo \"MISSING en backup: \$NAME\" >> \$REPORT
        MISSING=\$((MISSING + 1))
    else
        BAK_SIZE=\$(echo \"\$BAK_LINE\" | cut -d',' -f2)
        if [ \"\$SIZE\" != \"\$BAK_SIZE\" ]; then
            echo \"SIZE MISMATCH: \$NAME (origen=\$SIZE, backup=\$BAK_SIZE)\" >> \$REPORT
            MISMATCH=\$((MISMATCH + 1))
        else
            MATCH=\$((MATCH + 1))
        fi
    fi
done < \$SOURCE

echo '' >> \$REPORT
echo '========== RESUMEN ==========' >> \$REPORT
echo \"Coincidentes: \$MATCH\" >> \$REPORT
echo \"Missing:      \$MISSING\" >> \$REPORT
echo \"Mismatch:     \$MISMATCH\" >> \$REPORT

if [ \$MISSING -eq 0 ] && [ \$MISMATCH -eq 0 ]; then
    echo '' >> \$REPORT
    echo 'RESULTADO: BACKUP CONSISTENTE' >> \$REPORT
else
    echo '' >> \$REPORT
    echo 'RESULTADO: BACKUP INCONSISTENTE - revisar diferencias' >> \$REPORT
fi
echo '==============================' >> \$REPORT

cat \$REPORT
"

# Guardar resultados en HDFS
echo ""
echo "[inventory] Guardando resultados en /audit/inventory/$DT/ ..."
docker exec -it $NN_CONTAINER bash -lc "
hdfs dfs -put -f /tmp/inventory_source_${DT}.csv /audit/inventory/$DT/inventory_source.csv
hdfs dfs -put -f /tmp/inventory_backup_${DT}.csv /audit/inventory/$DT/inventory_backup.csv
hdfs dfs -put -f /tmp/inventory_report_${DT}.txt /audit/inventory/$DT/inventory_report.txt
"

# Copiar al volumen de notebooks
docker exec -it $NN_CONTAINER bash -lc "
mkdir -p /media/notebooks/audit/inventory/$DT
cp /tmp/inventory_source_${DT}.csv /media/notebooks/audit/inventory/$DT/
cp /tmp/inventory_backup_${DT}.csv /media/notebooks/audit/inventory/$DT/
cp /tmp/inventory_report_${DT}.txt /media/notebooks/audit/inventory/$DT/
"

# Limpiar temporales
docker exec -it $NN_CONTAINER bash -lc "rm -f /tmp/inventory_source_${DT}.csv /tmp/inventory_backup_${DT}.csv /tmp/inventory_report_${DT}.txt"

echo ""
echo "[inventory] Completado."
