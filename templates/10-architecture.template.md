---
# Activa esta regla SOLO cuando el contexto incluya estos ficheros.
# Sintaxis glob: * un nivel · ** recursivo · ? un carácter · {a,b} alternativas
# Sin este bloque la regla se carga SIEMPRE (no lo pongas en reglas genéricas).
paths:
  - "<main.py>"
  - "<src/api/**>"
---
# 10 — Arquitectura

## <Módulo 1>
- Clases: <...>
- Funciones clave: <...>
- Flujo: <a> → <b> → <c>

## <Módulo 2>
- <...>

## Lógica compartida <A> ↔ <B>
- Mismas funciones: <...>
- Diferencias intencionadas: <...> (confirmado por el usuario, no es un bug)

## Estado en disco
- <ficheros de estado, si los hay; no modificar>

## Despliegue
- <cómo, dónde y con qué comando exacto>
