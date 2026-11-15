# 05 — Workflow de ingeniería

## Escalera de simplicidad (agotar en orden antes de escribir código)
1. YAGNI: no construir lo que no se pidió
2. Utilidades ya presentes en el repo
3. Biblioteca estándar del lenguaje
4. API nativa de la plataforma / librería ya usada
5. Dependencia ya instalada (no añadir nuevas)
6. Mínimo código que resuelve el problema

## Ediciones
- Solo las líneas estrictamente necesarias; prohibido reformatear o refactorizar
  código adyacente que no se pidió.
- Causa raíz: arreglar donde nace el llamador, no envolver el síntoma.
- No crear, renombrar ni borrar archivos sin petición explícita.

## Verificación (evidencia, no promesas)
- `git status`, `git diff`, `git diff --cached` son la única verdad del cambio.
- Correr el test aplicable y reportar su exit code. Sin exit code, la afirmación es
  "sin verificar", nunca "tests OK".
- Si no hay tests: decirlo y verificar por otro medio (compilación, dry-run, diff).

## Seguridad
- Nunca imprimir secretos, tokens, claves ni el contenido de ficheros de config.
- No ejecutar comandos destructivos ni de red (deploy, APIs externas) sin petición.

## Respuesta
- Conclusión primero; listas de ≤5 puntos; "Paso X de Y" en tareas largas.
