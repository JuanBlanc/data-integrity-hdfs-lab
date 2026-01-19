# Proyecto: DataSecure Lab — Integridad de Datos en Big Data (HDFS)

## 1. Contexto
La empresa ficticia **DataSecure** gestiona datos sensibles (logs y telemetría IoT). La dirección exige un sistema reproducible que garantice la **integridad** de los datos en un ecosistema Big Data, especialmente durante:
- **ingesta** en HDFS,
- **verificación periódica** (detección temprana),
- **migración/copia** hacia un destino de backup,
- **respuesta ante incidentes** (corrupción o caída de nodo),
- y un **análisis del coste** de aplicar mecanismos de integridad.

## 2. Entorno disponible
En el aula disponéis de un ecosistema Docker con Hadoop:
- **NameNode UI**: `http://localhost:9870`
- **ResourceManager UI**: `http://localhost:8088`
- **Jupyter en NameNode**: `http://localhost:8889`

> El proyecto se evalúa sobre el entorno dockerizado del aula.  
> AWS Academy / EMR puede usarse como *extensión* (no obligatoria).

## 3. Objetivo general
Diseñar e implementar un flujo reproducible que:
1) genere y organice un dataset realista,  
2) lo ingiera en HDFS con estructura particionada,  
3) ejecute auditoría de integridad periódica,  
4) copie/migre los datos a un destino de “backup” (y valide integridad post-copia),  
5) simule un incidente realista y demuestre recuperación,  
6) mida y analice el coste de integridad (CPU/red/disco).

---

# 4. Requisitos del proyecto

## R1) Dataset + particionado (obligatorio)
Generar un dataset realista con dos familias de datos:
- **Logs**: `logs_YYYYMMDD.log`
- **IoT**: `iot_YYYYMMDD.jsonl` (JSON Lines)

Estructura obligatoria en HDFS (por fecha):
- `/data/logs/raw/dt=YYYY-MM-DD/`
- `/data/iot/raw/dt=YYYY-MM-DD/`

**Condición mínima**: el volumen debe ser suficiente para observar particionado y comportamiento de HDFS (recomendado: al menos 1–2 GB totales o ficheros > 512MB).

## R2) Parámetros HDFS (obligatorio)
Localizar y documentar (en el README):
- dónde se encuentran los ficheros XML de configuración,
- los valores de:
  - `dfs.blocksize`
  - `dfs.replication`

**Justificar** (en 8–12 líneas) por qué elegís esos valores, relacionándolo con integridad y coste.

> Nota: no se pide cambiar el algoritmo interno de checksum de HDFS.  
> Sí se pide explicar por qué CRC (por bloque) es habitual y qué aporta SHA/MD5 a nivel aplicación.

## R3) Ingesta en HDFS (obligatorio)
Cargar el dataset en HDFS respetando la estructura por fechas.
Evidencias mínimas:
- `hdfs dfs -ls -R /data`
- tamaños con `hdfs dfs -du -h /data`

## R4) Auditoría de integridad con fsck (obligatorio)
Implementar un script que:
- ejecute `hdfs fsck` sobre `/data` (y sobre el destino de backup si existe),
- guarde evidencias en:
  - `/audit/fsck/YYYYMMDD/`
- genere un **resumen** (texto o CSV) con conteos de:
  - `CORRUPT`, `MISSING`, `UNDER_REPLICATED` (si aparecen)

## R5) Copia/migración a “backup” + validación (obligatorio)
Debéis implementar un destino de backup y validar la copia.

### Opción A (base): backup dentro del mismo clúster (obligatorio mínimo)
- Copiar `/data/.../dt=.../` a `/backup/.../dt=.../`
- Validación post-copia:
  - inventario (rutas y tamaños) origen vs destino,
  - y auditoría `fsck` sobre `/backup`.

### Opción B (avanzada): segundo clúster HDFS + DistCp (extra nota)
- Montar un segundo clúster dockerizado (Cluster B).
- Ejecutar `hadoop distcp` de Cluster A → Cluster B.
- Validar post-copia con inventario + auditoría.

## R6) Incidente controlado + recuperación (obligatorio)
Simular un incidente y demostrar:
- detección (auditoría, lectura o estado HDFS),
- recuperación (re-replicación o restauración desde backup).

Incidentes válidos:
- caída de un DataNode durante una operación (stop/start del contenedor),
- corrupción simulada (avanzada): modificación controlada de un bloque en un DataNode (documentando el procedimiento).

## R7) Métricas y análisis coste/beneficio (obligatorio)
Medir y reportar (tabla):
- tiempo de ingestión,
- tiempo de copia/migración,
- impacto de replicación (comparar 1 vs 2 vs 3; si hay 4 DN, incluir 4 como extra),
- evidencias de uso de recursos (capturas o logs de `docker stats`).

Conclusión obligatoria:
- recomendación final de replicación y “frecuencia” de auditoría (diaria, semanal…),
- justificándolo por coste y riesgo.

---

# 5. Entregables (resumen)
- `README.md` con Quickstart, arquitectura y guía de reproducción.
- Scripts completados en `/scripts`.
- Evidencias en `docs/evidencias.md`.
- Al menos 1 notebook en `/notebooks` con tabla de auditorías/métricas y conclusiones.

---

# 6. Bonus (opcional)
- DistCp real (Variante B): +5 a +10
- Hash end-to-end (sha256) auditado: +2 a +5
- Automatización tipo “daily run” (cron/scheduler): +2 a +5
