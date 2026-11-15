# Memory Bank — Protocolo (OBLIGATORIO)
Ubicación: memory-bank/ (5 archivos, cada uno ≤40 líneas)
- projectbrief.md — qué es el proyecto, propósito, alcance
- techContext.md — stack, dependencias, comandos clave
- systemPatterns.md — arquitectura, flujos, convenciones
- activeContext.md — tarea actual, decisiones, puntos abiertos
- progress.md — qué está hecho, qué falta, próximos pasos
## Al iniciar una tarea
1. PRIMERA acción: leer SOLO activeContext.md y progress.md (si existen). No explores el repo antes.
2. Si ya vienen inyectados en el contexto, no los releas.
3. Leer el resto solo si la tarea lo requiere.
4. systemPatterns.md sirve para orientarte, pero ANTES DE EDITAR un archivo, léelo: el código manda sobre el memory bank.
5. Si memory-bank/ no existe, continúa sin él y avísame. No lo crees por tu cuenta.
## Al terminar (ÚLTIMA acción antes de attempt_completion)
1. Si la tarea cambió código o tomó decisiones: REESCRIBIR (no acumular) activeContext.md y progress.md.
2. Si fue solo una consulta: no actualices nada.
3. Si pido "update memory bank": reescribe ambos siempre.
4. Anota como hecho SOLO lo ejecutado o comprobado ("tests OK" solo si los corriste). Si no, escribe "sin verificar".
5. Si un archivo supera su límite, condénsalo antes de guardarlo. Frases telegráficas; referencia rutas, no pegues código.
6. Ver el flujo de revisión en .clinerules/30-review-workflow.md y las reglas de
   edición en .clinerules/05-workflow.md.

## Prohibido guardar
- Secretos: claves de APIs, tokens, credenciales, claves de cifrado
- Datos personales o fiscales
- Valores de parámetros de la estrategia: referenciar archivo + nombre de constante
- Código largo: referenciar archivo + función
