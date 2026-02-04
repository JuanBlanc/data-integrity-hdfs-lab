# Evidencias

> Fecha de ejecución: _(completar con la fecha de ejecución real)_
> Clúster: 3 DataNodes (`docker compose up -d --scale dnnm=3`)

## 1) NameNode UI (9870)

### DataNodes vivos y capacidad
_(Incluir captura de http://localhost:9870 mostrando Live Nodes)_

### Verificación CLI
```
(Pegar salida de: docker exec -it namenode bash -lc "hdfs dfsadmin -report | head -30")
```

---

## 2) Auditoría fsck

### Salida de `hdfs fsck /data` (bloques/locations)
```
(Pegar salida del script 30_fsck_audit.sh o de: docker exec -it namenode bash -lc "hdfs fsck /data -files -blocks -locations")
```

### Resumen de auditoría
| Métrica | Valor |
|---------|-------|
| CORRUPT | _(completar)_ |
| MISSING | _(completar)_ |
| UNDER_REPLICATED | _(completar)_ |
| HEALTHY | _(completar)_ |

---

## 3) Backup + validación

### Inventario origen vs destino
```
(Pegar salida del script 50_inventory_compare.sh)
```

### Resultado de comparación
- Ficheros coincidentes: _(completar)_
- Missing: _(completar)_
- Size mismatch: _(completar)_
- **Resultado**: _(CONSISTENTE / INCONSISTENTE)_

---

## 4) Incidente + recuperación

### Incidente simulado
- **Tipo**: Caída de DataNode
- **DataNode detenido**: _(completar con nombre del contenedor)_
- **Fecha/hora**: _(completar)_

### Estado ANTES del incidente
```
(Pegar resumen fsck pre-incidente)
```

### Estado DESPUÉS del incidente
```
(Pegar resumen fsck post-incidente)
```

### Recuperación
- **Método**: Re-arranque del DataNode + re-replicación automática de HDFS
- **Resultado**: _(completar)_

### Estado FINAL (post-recuperación)
```
(Pegar resumen fsck final)
```

---

## 5) Métricas

### Tiempos de ejecución

| Operación | Tiempo (segundos) |
|-----------|-------------------|
| Generación de datos (10_generate_data.sh) | _(completar)_ |
| Ingesta logs a HDFS | _(completar)_ |
| Ingesta IoT a HDFS | _(completar)_ |
| Copia backup logs | _(completar)_ |
| Copia backup IoT | _(completar)_ |

### Impacto de replicación (generado por `60_replication_metrics.sh`)

| Factor replicación | Espacio lógico | Espacio físico | Tiempo setrep (s) | Observaciones |
|--------------------|----------------|----------------|-------------------|---------------|
| 1 | _(completar)_ | _(completar)_ | _(completar)_ | Sin tolerancia a fallos |
| 2 | _(completar)_ | _(completar)_ | _(completar)_ | Tolera 1 fallo |
| 3 | _(completar)_ | _(completar)_ | _(completar)_ | Tolera 1 fallo + re-replicación |

### Docker stats (capturado por `60_replication_metrics.sh`)
```
(Pegar salida de docker stats --no-stream, generada automáticamente por el script 60)
```

### Conclusión y recomendación
_(Completar con recomendación de factor de replicación y frecuencia de auditoría, justificado con los datos recogidos)_
