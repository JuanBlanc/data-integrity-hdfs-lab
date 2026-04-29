# Entrega (individual)

## 1) Cómo entregar
1. Haz un **fork** de este repositorio en tu cuenta de GitHub.
2. Trabaja en tu fork y deja el resultado final en la rama **main**.
3. Crea un **tag obligatorio** de entrega: `v1.0-entrega`
4. Entrega el **enlace** a tu repositorio (y opcionalmente, el enlace a la Release asociada al tag).

> Importante: se corregirá **la versión etiquetada** con `v1.0-entrega`.  
> Si el tag no existe o no está actualizado, se evaluará con penalización en “Reproducibilidad”.

---

## 2) Requisitos mínimos
Tu repositorio debe incluir:

- `README.md` con **Quickstart reproducible** (copiar/pegar y funciona).
- Carpeta `/scripts` con los scripts del pipeline completados.
- `docs/evidencias.md` con capturas/salidas (orden estándar).
- Al menos 1 notebook en `/notebooks` con:
  - lectura de auditorías (fsck),
  - una tabla de métricas (tiempos/recursos),
  - conclusiones y recomendaciones.

---

## 3) Quickstart obligatorio (para corrección)
Incluye este bloque (o equivalente) en tu `README.md`:

```bash
cd docker/clusterA && docker compose up -d
bash scripts/00_bootstrap.sh && bash scripts/10_generate_data.sh && bash scripts/20_ingest_hdfs.sh
bash scripts/30_fsck_audit.sh && bash scripts/40_backup_copy.sh && bash scripts/50_inventory_compare.sh
bash scripts/70_incident_simulation.sh && bash scripts/80_recovery_restore.sh
```

---

## 4) Evidencias (plantilla y orden)
Rellena `docs/evidencias.md` respetando este orden (así se corrige más rápido):

1. **NameNode UI (9870)**: DataNodes vivos y capacidad.
2. **Auditoría fsck**: bloques/locations y resumen (CORRUPT/MISSING/UNDER_REPLICATED).
3. **Backup + validación**: inventario origen vs destino y consistencia.
4. **Incidente + recuperación**: qué hiciste + evidencia antes/después.
5. **Métricas**: capturas de `docker stats` y tabla de tiempos.

---

## 5) Recomendación para evitar problemas
- No subas ficheros enormes al repo (usa `.gitignore`).
- Parametriza fecha (`DT=YYYY-MM-DD`) para que tus scripts funcionen “en cualquier día”.
- Documenta cualquier supuesto (nombres de contenedores, rutas, puertos).

---

## 6) Cómo crear el tag `v1.0-entrega` (recordatorio)
Desde tu repo (en local):

```bash
git tag v1.0-entrega
git push origin v1.0-entrega
```

Si quieres actualizar el tag (evitar si puedes), debes borrarlo y recrearlo:

```bash
git tag -d v1.0-entrega
git push origin :refs/tags/v1.0-entrega
git tag v1.0-entrega
git push origin v1.0-entrega
```
