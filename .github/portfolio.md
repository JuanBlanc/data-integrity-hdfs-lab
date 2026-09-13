---
title: DataSecure · Integridad de datos en HDFS
description: Ingesta, auditoría, backup, incidente y recuperación sobre un clúster Hadoop de tres DataNodes, paso a paso.
slug: data-integrity-hdfs
tags: [Hadoop, HDFS, Bash, Docker]
cover: docs/imgs/13_replication_metrics.png
order: 5
---

Integridad de datos sobre un ecosistema **Hadoop dockerizado**, con el recorrido
entero y no solo la parte cómoda: generar cerca de un gigabyte de logs y lecturas
IoT, ingerirlos en HDFS particionados por fecha, auditar la integridad, copiarlos
validando la copia, tirar un DataNode a propósito y recuperarse.

## El clúster y el pipeline

```
NameNode :9870   ResourceManager :8088   DataNode x3
Jupyter  :8889

HDFS
  /data/logs/raw/dt=YYYY-MM-DD/     datos de logs
  /data/iot/raw/dt=YYYY-MM-DD/      datos IoT
  /backup/.../dt=YYYY-MM-DD/        copia
  /audit/fsck/YYYY-MM-DD/           auditorías
  /audit/inventory/YYYY-MM-DD/      inventarios
```

Nueve scripts numerados, uno por fase, del `00_bootstrap` al `80_recovery_restore`.
Está hecho así para poder parar en cualquier punto y retomar sin rehacer lo
anterior: la fecha de trabajo es una variable (`DT`), los directorios de auditoría
van fechados, y cada paso deja su salida escrita en HDFS antes de que empiece el
siguiente.

```bash
cd docker/clusterA && docker compose up -d --scale dnnm=3
cd ../..
bash scripts/30_fsck_audit.sh          # auditoría de integridad
bash scripts/50_inventory_compare.sh   # ¿la copia es la misma cosa?
bash scripts/70_incident_simulation.sh # cae un DataNode
bash scripts/80_recovery_restore.sh    # y se vuelve del incidente
```

## Lo que se decidió y por qué

**Replicación 3 con tres DataNodes.** Triplica el disco, y a cambio el clúster
sobrevive a la caída de un nodo entero sin perder un bloque. Factor 2 ahorra un
tercio pero no tolera un fallo *durante* la re-replicación, que es justo cuando
más probable es que ocurra el segundo. Los scripts miden el coste de las tres
opciones (1, 2 y 3) en lugar de afirmarlo.

**Bloque de 128 MB.** Con ficheros de medio giga son cuatro bloques: hay
paralelismo de lectura sin fragmentar. Bajar a 64 MB duplica las entradas que el
NameNode mantiene en memoria; subir a 256 MB deja media lectura sin paralelizar.

**Validar la copia por inventario, no por hash de aplicación.** HDFS ya verifica
un CRC-32C por bloque en cada lectura y escritura, y eso cubre la corrupción
silenciosa de disco sin que nadie haga nada. Un SHA-256 extremo a extremo añade
una garantía real cuando los datos cruzan de un sistema a otro, pero hay que
generarlo, guardarlo y compararlo, y cuesta CPU sobre un gigabyte. Para
integridad dentro del clúster, comparar conteo y tamaños de origen contra destino
da la respuesta que se necesita con el coste que corresponde.

La parte que más enseña es la última: comprobar que lo recuperado tras el
incidente es idéntico a lo que había antes de provocarlo.

## Dónde está lo demás

El enunciado, la rúbrica, los requisitos de despliegue y las evidencias con
capturas de cada fase están en `docs/`.
