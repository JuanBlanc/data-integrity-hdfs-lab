# Rúbrica — DataSecure Lab (100 puntos + bonus)

## A) Reproducibilidad y calidad del repo (20 pts)
- **0–8**: scripts incompletos o ejecución manual poco clara  
- **9–15**: ejecución posible, README correcto, estructura aceptable  
- **16–20**: ejecución “1 comando por fase”, repo limpio, parametrizado, instrucciones claras  

## B) Dataset e ingesta particionada (10 pts)
- **0–4**: dataset pequeño, estructura incorrecta o sin particionado  
- **5–8**: dataset y particiones correctas, evidencias básicas  
- **9–10**: dataset realista, particionado coherente, validación de tamaños y rutas  

## C) Configuración HDFS + justificación (10 pts)
- **0–4**: no localiza XML ni justifica  
- **5–8**: identifica parámetros y explica mínimamente  
- **9–10**: explica trade-off integridad/coste, conecta con resultados medidos  

## D) Auditoría de integridad (fsck) (15 pts)
- **0–6**: fsck manual y sin evidencias guardadas  
- **7–12**: auditoría automatizada, evidencias en `/audit`, resumen básico  
- **13–15**: auditoría completa, resumen claro, interpretación de estados y acciones recomendadas  

## E) Backup + validación post-copia (15 pts)
- **0–6**: copia sin validación o inconsistencias no detectadas  
- **7–12**: copia correcta + inventario (tamaños/rutas) + fsck  
- **13–15**: validación sólida, detección de diferencias, logs claros, idempotencia  

## F) Incidente + recuperación demostrada (20 pts)
- **0–8**: incidente superficial o sin recuperación demostrada  
- **9–16**: incidente realista + detección + recuperación con evidencias  
- **17–20**: además, análisis de causa/impacto y prevención (replicación, auditoría, backup)  

## G) Métricas y conclusiones (10 pts)
- **0–4**: sin métricas o sin relación con decisiones  
- **5–8**: tabla de métricas + explicación razonable  
- **9–10**: conclusiones justificadas con datos (tiempos, recursos, replicación, frecuencia)  

---

## Bonus (hasta +10 pts)
- **Variante B** (dos clústeres + DistCp real) bien implementada: **+5 a +10**  
- Hash end-to-end (`sha256`) integrado y auditado: **+2 a +5**  
- Automatización tipo “daily run” (cron/scheduler): **+2 a +5**  
