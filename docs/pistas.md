# Pistas rápidas — Integridad en HDFS (Docker Hadoop)

## 1) Dónde mirar XML (rutas posibles)

| Qué buscas | Variable/Ruta típica | Cómo comprobarlo (comando) | Qué ficheros mirar |
|---|---|---|---|
| Directorio de configuración Hadoop | `$HADOOP_CONF_DIR` | `echo $HADOOP_CONF_DIR` | `core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `mapred-site.xml` |
| Config “clásica” en Linux | `/etc/hadoop/` | `ls -la /etc/hadoop 2>/dev/null` | idem |
| Config dentro del home Hadoop | `$HADOOP_HOME/etc/hadoop/` | `echo $HADOOP_HOME && ls -la $HADOOP_HOME/etc/hadoop 2>/dev/null` | idem |
| Config en imágenes “custom” | `/opt/hadoop/etc/hadoop/` o `/opt/bd/...` | `ls -la /opt/hadoop/etc/hadoop 2>/dev/null; ls -la /opt/bd 2>/dev/null` | idem |

### Parámetros clave (normalmente en `hdfs-site.xml`)
- **Tamaño de bloque**: `dfs.blocksize`  
- **Replicación por defecto**: `dfs.replication`

### Cómo consultar valores efectivos (sin abrir XML)
- Blocksize:
```bash
hdfs getconf -confKey dfs.blocksize
```
- Replicación por defecto:
```bash
hdfs getconf -confKey dfs.replication
```

> Consejo: si el valor no aparece en XML, puede venir por “defaults” del Hadoop o por scripts de arranque de la imagen.

---

## 2) Comandos clave (con qué sirven y ejemplos)

| Comando | Para qué sirve | Ejemplo recomendado | Qué evidencia genera |
|---|---|---|---|
| `hdfs dfsadmin -report` | Ver DataNodes vivos, capacidad, uso y estado | `hdfs dfsadmin -report` | Nº de DataNodes, GB usados/libres, nodos vivos |
| `hdfs fsck` | Auditoría de integridad, bloques, ubicaciones, under-replication | `hdfs fsck /data -files -blocks -locations` | HEALTHY/ CORRUPT / Missing / Under replicated + ubicaciones |
| `hdfs dfs -setrep -w` | Cambiar replicación y esperar a que se aplique | `hdfs dfs -setrep -w 3 /data/logs/raw/dt=2026-01-19/` | Evidencia de que se aplica replicación; útil para medir coste |
| `hdfs dfs -ls -R` | Inventario de rutas (origen/destino) | `hdfs dfs -ls -R /data` | Lista de ficheros por rutas y tamaños |
| `hdfs dfs -du -h` | Tamaños por directorio | `hdfs dfs -du -h /data` | Tamaño “lógico” por path |
| `hdfs dfs -stat` | Inventario “estructurado” para comparar | `hdfs dfs -stat '%n,%b,%y' /data/logs/raw/dt=.../*` | CSV fácil para comparar |
| `hadoop distcp` | Copia entre HDFS (multi-clúster) | `hadoop distcp hdfs://A:8020/data/... hdfs://B:8020/backup/...` | Logs de copia, tiempos y consistencia |

### Plantillas para el proyecto
- Auditoría guardada:
```bash
DT=$(date +%F)
hdfs fsck /data -files -blocks -locations | tee /tmp/fsck_data_${DT}.txt
hdfs dfs -mkdir -p /audit/fsck/${DT}
hdfs dfs -put -f /tmp/fsck_data_${DT}.txt /audit/fsck/${DT}/fsck_data.txt
```

- Replicación “experimento”:
```bash
hdfs dfs -setrep -w 1 /data/.../file.bin
hdfs dfs -setrep -w 2 /data/.../file.bin
hdfs dfs -setrep -w 3 /data/.../file.bin
```

---

## 3) Cómo sacar evidencias de UI (9870 / 8088)

### 3.1 NameNode UI — `http://localhost:9870`
**Qué capturar (mínimo):**
1) **Overview / Summary**: capacidad total/usada, estado general.
2) **Datanodes / Live Nodes**: número de DataNodes vivos y sus nombres.
3) **Browse filesystem**: navegar a `/data/...` y `/backup/...` (si existe).

**Pistas de navegación (varía según versión):**
- Menú “Datanodes” → Live Nodes / Dead Nodes  
- Menú “Utilities” → Browse the filesystem  

**Evidencia esperada:**
- Captura con DataNodes vivos.
- Captura mostrando los ficheros en `/data` y `/backup`.

### 3.2 ResourceManager UI — `http://localhost:8088`
**Qué capturar (mínimo si se usa YARN):**
1) **Cluster metrics**: NodeManagers activos, memoria/CPU.
2) **Applications**: si lanzáis un job (opcional).

**Evidencia esperada:**
- Captura del estado del clúster YARN (NodeManagers activos).
- (Opcional) captura de un job ejecutado.

---

## 4) Comandos “docker exec” típicos (desde el host)

```bash
docker exec -it namenode bash -lc "hdfs dfsadmin -report | head -n 80"
docker exec -it namenode bash -lc "hdfs fsck /data -files -blocks -locations | head -n 200"
docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.blocksize"
docker exec -it namenode bash -lc "hdfs getconf -confKey dfs.replication"
```

> Si tu contenedor tiene otro nombre, cambia `namenode` por el nombre real (`docker ps`).
