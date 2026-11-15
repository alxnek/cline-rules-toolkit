---
paths:
  - "test_*"
  - "**/test_*"
  - "**/tests/**"
---
# 20 — Tests

## Framework
- Runner: <pytest / jest / scripts standalone / ...>
- Directorio de tests: <ruta>
- <Si no hay suite: dilo explícitamente aquí.>

## Cómo ejecutar
- Todo: `<comando>`
- Uno solo: `<comando con filtro>`
- Devuelve exit code: <sí / no, 0 = OK>

## Cobertura mínima
- Cambios en <módulo A> → `<comando A>`
- Cambios en <módulo B> → `<comando B>` (lento: confirmación previa)
- Cambios en <producción> → si no hay test directo: <checklist o paridad>

## Evidencia obligatoria
- Todo cambio de código: ejecutar el test aplicable y reportar su exit code.
- Sin ejecución → la afirmación es "sin verificar", nunca "tests OK".
- Tests lentos requieren confirmación previa.
