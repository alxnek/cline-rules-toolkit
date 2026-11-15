# 30 — Flujo de revisión en 3 etapas (cambios no triviales)

## Etapa 1 — Plan
- Inspeccionar el código real antes de proponer nada.
- Plan de ≤5 pasos. No editar hasta que esté aprobado.

## Etapa 2 — Red-team adversarial (misma sesión, antes de implementar)
- Revisar el plan buscando fallos: APIs inexistentes, efectos colaterales,
  sobre-ingeniería, supuestos sin verificar, pasos que faltan.
- No implementar nada en esta etapa. Devolver objeciones concretas o "plan OK".
- Alternativa de más frescura: pedir esta revisión en una conversación nueva.

## Etapa 3 — Production readiness (antes de cerrar)
- `git diff` crudo: confirmar que solo cambió lo pedido.
- Test aplicable ejecutado + exit code real.
- Si hay código en producción: verificar su checklist de paridad y su plan aprobado.
- Actualizar la memoria del proyecto si cambió código o hubo decisiones.

## Fuera de alcance
- Cambios triviales (typos, un valor): solo etapas 1 y 3.
- Producción y ficheros de estado: siguen exigiendo plan aprobado.
