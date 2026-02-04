#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=${OUT_DIR:-./data_local}
DT=${DT:-$(date +%F)}
DT_COMPACT=${DT//-/}
mkdir -p "$OUT_DIR/$DT"

LOG_FILE="$OUT_DIR/$DT/logs_${DT_COMPACT}.log"
IOT_FILE="$OUT_DIR/$DT/iot_${DT_COMPACT}.jsonl"

# Número de líneas (~512MB por fichero, ~1GB total)
TARGET_LINES_LOGS=3000000
TARGET_LINES_IOT=2500000

echo "============================================"
echo "[generate] Generando dataset realista"
echo "[generate] DT=$DT"
echo "[generate] Salida en: $OUT_DIR/$DT"
echo "============================================"

# ---------- LOGS (generado con awk — rápido) ----------
echo "[generate] Generando logs ($TARGET_LINES_LOGS líneas)..."

awk -v n="$TARGET_LINES_LOGS" -v dt="$DT" 'BEGIN {
    srand()
    split("user001,user002,user003,user004,user005,user006,user007,user008,user009,user010,admin01,admin02,svc_app,svc_batch,svc_api", users, ",")
    split("LOGIN,LOGOUT,UPLOAD,DOWNLOAD,DELETE,VIEW,EDIT,SEARCH,EXPORT,IMPORT,CREATE_USER,UPDATE_PROFILE,CHANGE_PASSWORD,API_CALL,BATCH_JOB", actions, ",")
    split("OK,OK,OK,OK,OK,OK,OK,ERROR,WARN,TIMEOUT", statuses, ",")
    split("web,api,mobile,batch,cli", sources, ",")
    nu = 15; na = 15; ns = 10; nsr = 5

    for (i = 1; i <= n; i++) {
        h  = int(rand() * 24)
        m  = int(rand() * 60)
        s  = int(rand() * 60)
        ms = int(rand() * 1000)
        printf "%sT%02d:%02d:%02d.%03dZ | %s | 192.168.%d.%d | %s | sess-%08x | %s | %s | bytes=%d | msg=Request processed\n", \
            dt, h, m, s, ms, \
            sources[int(rand()*nsr)+1], \
            int(rand()*256), int(rand()*256), \
            users[int(rand()*nu)+1], \
            int(rand()*2147483647), \
            actions[int(rand()*na)+1], \
            statuses[int(rand()*ns)+1], \
            int(rand()*3276700)+1
        if (i % 500000 == 0) printf "[generate]   ... %d / %d líneas de logs\n", i, n > "/dev/stderr"
    }
}' > "$LOG_FILE"

LOG_SIZE=$(du -h "$LOG_FILE" | cut -f1)
echo "[generate] Logs generados: $LOG_FILE ($LOG_SIZE)"

# ---------- IoT JSONL (generado con awk — rápido) ----------
echo "[generate] Generando IoT JSONL ($TARGET_LINES_IOT líneas)..."

awk -v n="$TARGET_LINES_IOT" -v dt="$DT" 'BEGIN {
    srand()
    split("sensor-temp-001,sensor-temp-002,sensor-hum-001,sensor-hum-002,sensor-press-001,sensor-light-001,sensor-light-002,actuator-valve-001,actuator-pump-001,actuator-fan-001,gateway-north,gateway-south,gateway-east,gateway-west", devices, ",")
    split("temperature,humidity,pressure,luminosity,voltage,flow_rate,rpm,vibration", metrics, ",")
    split("plant-A,plant-B,warehouse-1,warehouse-2,office-main,datacenter-1", locations, ",")
    nd = 14; nm = 8; nl = 6

    for (i = 1; i <= n; i++) {
        h = int(rand() * 24)
        m = int(rand() * 60)
        s = int(rand() * 60)
        val = int(rand() * 10000) / 100.0
        q = 95 + int(rand() * 6)
        printf "{\"deviceId\":\"%s\",\"ts\":\"%sT%02d:%02d:%02dZ\",\"metric\":\"%s\",\"value\":%.2f,\"unit\":\"auto\",\"location\":\"%s\",\"quality\":%d,\"batchId\":\"batch-%06x\"}\n", \
            devices[int(rand()*nd)+1], \
            dt, h, m, s, \
            metrics[int(rand()*nm)+1], \
            val, \
            locations[int(rand()*nl)+1], \
            q, \
            int(rand()*16777215)
        if (i % 500000 == 0) printf "[generate]   ... %d / %d líneas de IoT\n", i, n > "/dev/stderr"
    }
}' > "$IOT_FILE"

IOT_SIZE=$(du -h "$IOT_FILE" | cut -f1)
echo "[generate] IoT generado: $IOT_FILE ($IOT_SIZE)"

echo ""
echo "[generate] Resumen:"
du -sh "$OUT_DIR/$DT"/*
echo ""
echo "[generate] Completado."
