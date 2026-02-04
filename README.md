# DataSecure Lab — Integridad de Datos en Big Data (HDFS)

Proyecto práctico de **Integridad de Datos en Big Data** sobre un ecosistema **Hadoop dockerizado**. Implementa un flujo completo: generación de datos, ingesta en HDFS, auditoría de integridad, backup con validación, simulación de incidentes y recuperación.

- Enunciado: `docs/enunciado_proyecto.md`
- Rúbrica: `docs/rubric.md`
- Pistas rápidas: `docs/pistas.md`
- Entrega (individual): `docs/entrega.md`
- Evidencias: `docs/evidencias.md`

---

## Quickstart (para corrección)

```bash
# 1. Levantar clúster con 3 DataNodes
cd docker/clusterA && docker compose up -d --scale dnnm=3

# 2. Volver a la raíz del proyecto
cd ../..

# 3. Ejecutar pipeline completo
bash scripts/00_bootstrap.sh
bash scripts/10_generate_data.sh
bash scripts/20_ingest_hdfs.sh
bash scripts/30_fsck_audit.sh
bash scripts/40_backup_copy.sh
bash scripts/50_inventory_compare.sh
bash scripts/60_replication_metrics.sh
bash scripts/70_incident_simulation.sh
bash scripts/80_recovery_restore.sh
```

> Variables configurables:
> - `DT=YYYY-MM-DD` — fecha de trabajo (por defecto: hoy)
> - `NN_CONTAINER=namenode` — nombre del contenedor NameNode

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                    Host (Docker)                     │
│                                                     │
│  ┌──────────┐  ┌───────────────┐  ┌──────────────┐ │
│  │ NameNode │  │ResourceManager│  │  DataNode x3  │ │
│  │  :9870   │  │    :8088      │  │  (dnnm)       │ │
│  │  :8889   │  │               │  │               │ │
│  │ (Jupyter)│  │               │  │               │ │
│  └──────────┘  └───────────────┘  └──────────────┘ │
│                                                     │
│  HDFS:                                              │
│  /data/logs/raw/dt=YYYY-MM-DD/   ← datos logs      │
│  /data/iot/raw/dt=YYYY-MM-DD/    ← datos IoT       │
│  /backup/.../dt=YYYY-MM-DD/      ← copia backup    │
│  /audit/fsck/YYYY-MM-DD/         ← auditorías      │
│  /audit/inventory/YYYY-MM-DD/    ← inventarios      │
└─────────────────────────────────────────────────────┘
```

### Pipeline de scripts

| Fase | Script | Descripción |
|------|--------|-------------|
| 0 | `00_bootstrap.sh` | Crear estructura de directorios en HDFS |
| 1 | `10_generate_data.sh` | Generar dataset realista (~1GB: logs + IoT) |
| 2 | `20_ingest_hdfs.sh` | Subir datos a HDFS con particionado por fecha |
| 3 | `30_fsck_audit.sh` | Auditoría de integridad con `hdfs fsck` |
| 4 | `40_backup_copy.sh` | Copiar datos a `/backup` (Variante A) |
| 5 | `50_inventory_compare.sh` | Validar backup: inventario origen vs destino |
| 6 | `60_replication_metrics.sh` | Métricas de replicación (1 vs 2 vs 3) y `docker stats` |
| 7 | `70_incident_simulation.sh` | Simular caída de DataNode |
| 8 | `80_recovery_restore.sh` | Recuperación y auditoría final |

---

## Configuración HDFS (R2)

### Ubicación de ficheros de configuración

Los ficheros XML de configuración de Hadoop se encuentran dentro de los contenedores en:
- `/opt/bd/` o `$HADOOP_CONF_DIR` (según la imagen del profesor)
- Ficheros clave: `hdfs-site.xml`, `core-site.xml`

Para consultar los valores efectivos sin abrir XML:
```bash
docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.blocksize"
docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.replication"
```

### Parámetros y justificación

| Parámetro | Valor recomendado | Justificación |
|-----------|-------------------|---------------|
| `dfs.blocksize` | 128 MB (por defecto) | Adecuado para ficheros de ~512MB: genera 4 bloques por fichero, permitiendo paralelismo en lectura sin excesiva fragmentación. Bloques más pequeños (64MB) aumentarían la carga del NameNode; bloques mayores (256MB) reducirían el paralelismo. |
| `dfs.replication` | 3 (con 3 DataNodes) | Factor 3 garantiza tolerancia a la caída de un nodo completo sin pérdida de datos. Cada bloque se almacena en 3 DataNodes distintos, triplicando el uso de disco pero proporcionando alta disponibilidad. Factor 2 reduce coste un 33% pero no tolera fallos durante re-replicación. Factor 1 no ofrece tolerancia a fallos. |

### Integridad: CRC nativo vs SHA/MD5 a nivel de aplicación

HDFS utiliza checksums CRC-32C a nivel de bloque de forma nativa y transparente. Cada vez que un bloque se lee o se escribe, el DataNode verifica el CRC automáticamente, detectando corrupción silenciosa de disco (bit rot). Este mecanismo es eficiente en CPU y opera sin intervención del usuario.

A nivel de aplicación, añadir SHA-256 o MD5 como hash end-to-end proporciona una capa adicional de validación: permite verificar que un fichero completo no ha sido alterado entre sistemas (por ejemplo, tras una migración con DistCp o una restauración desde backup). Sin embargo, SHA/MD5 a nivel de aplicación tiene mayor coste computacional y debe gestionarse manualmente (generar, almacenar y comparar hashes).

Para este proyecto, el CRC nativo de HDFS es suficiente para la integridad intra-clúster, mientras que la validación por inventario (tamaños y conteo de ficheros) ofrece un balance razonable entre seguridad y complejidad.

---

## Servicios y UIs
- NameNode UI: http://localhost:9870
- ResourceManager UI: http://localhost:8088
- Jupyter (NameNode): http://localhost:8889

---

## Estructura del repositorio
```
data-integrity-hdfs-lab/
├── README.md
├── .gitignore
├── docker/clusterA/
│   ├── docker-compose.yml
│   └── notebooks/          ← montado en NameNode (/media/notebooks)
├── scripts/                 ← pipeline bash (9 scripts)
├── notebooks/               ← análisis Jupyter
└── docs/                    ← documentación completa
```

---

## Normas de entrega (individual)
Consulta `docs/entrega.md`.
**Obligatorio:** tag final `v1.0-entrega`.
