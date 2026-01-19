# DataSecure Lab — Integridad de Datos en Big Data (HDFS)

Repositorio base del proyecto práctico **Integridad de Datos en Big Data** usando un ecosistema **Hadoop dockerizado** del aula.

- 📄 Enunciado: `docs/enunciado_proyecto.md`
- ✅ Rúbrica: `docs/rubric.md`
- 🧭 Pistas rápidas: `docs/pistas.md`
- 🧾 Entrega (individual): `docs/entrega.md`
- 📎 Plantilla de evidencias: `docs/evidencias.md`

---

## Quickstart (para corrección)

```bash
cd docker/clusterA && docker compose up -d
bash scripts/00_bootstrap.sh && bash scripts/10_generate_data.sh && bash scripts/20_ingest_hdfs.sh
bash scripts/30_fsck_audit.sh && bash scripts/40_backup_copy.sh && bash scripts/50_inventory_compare.sh
bash scripts/70_incident_simulation.sh && bash scripts/80_recovery_restore.sh
```

> Si algún script necesita variables:  
> `DT=YYYY-MM-DD` (fecha) y `NN_CONTAINER=namenode` (nombre del contenedor NameNode).

---

## Servicios y UIs
- NameNode UI: http://localhost:9870
- ResourceManager UI: http://localhost:8088
- Jupyter (NameNode): http://localhost:8889

---

## Estructura del repositorio
- `docker/clusterA/`: docker-compose del aula (Cluster A)
- `scripts/`: pipeline (generación → ingesta → auditoría → backup → incidente → recuperación)
- `notebooks/`: análisis en Jupyter (tabla de auditorías y métricas)
- `docs/`: documentación (enunciado, rúbrica, pistas, entrega, evidencias)

---

## Normas de entrega (individual)
Consulta `docs/entrega.md`.  
**Obligatorio:** tag final `v1.0-entrega`.

---

## Nota
Este repositorio es un “starter kit”: algunos scripts contienen **TODOs** para completar el proyecto.
