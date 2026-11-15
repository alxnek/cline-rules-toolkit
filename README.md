# cline-rules-toolkit

Reglas de ingeniería para Cline, reutilizables entre proyectos. Fuente única de
verdad: se editan aquí y se instalan en cada proyecto con `install.ps1`.

## Qué hay dentro

```text
cline-rules-toolkit/
├── README.md
├── rules/                        # reglas genéricas → se instalan tal cual
│   ├── 05-workflow.md            # universal, sin paths:
│   ├── 30-review-workflow.md     # universal, sin paths:
│   └── memory-bank.md            # protocolo de memoria (requiere memory-bank/)
├── templates/                    # esqueletos → se copian y se rellenan a mano
│   ├── 00-overview.template.md
│   ├── 10-architecture.template.md
│   ├── 20-testing.template.md
│   └── .clineignore.template
├── install.ps1                   # instala rules/
└── install-templates.ps1         # instala templates/
```

Los ficheros de `rules/` son **genéricos**: no mencionan ningún proyecto concreto
y se instalan tal cual. Los específicos de cada repo (`00-overview.md`, arquitectura,
rutas, comandos de test) van en `templates/` como esqueletos, porque su contenido
depende de cada proyecto.

## Instalar en un proyecto

```powershell
# Vista previa (no escribe nada)
.\install.ps1 -Project 'D:\proyectos\mi-app' -WhatIf

# Instalar
.\install.ps1 -Project 'D:\proyectos\mi-app'

# Solo algunos ficheros
.\install.ps1 -Project 'D:\proyectos\mi-app' -Files 05-workflow.md
```

Comportamiento:

| Situación | Qué hace |
|---|---|
| `.clinerules` no existe | lo crea |
| fichero no existe en el destino | lo copia (`+`) |
| fichero idéntico | lo salta (`=`), es idempotente |
| fichero distinto | backup en `.clinerules.bak\<timestamp>\` y copia (`~`) |

Nunca borra ficheros del proyecto destino ni toca nada fuera de `.clinerules`.
Si la ejecución está bloqueada por política: `powershell -ExecutionPolicy Bypass -File .\install.ps1 ...`

## Instalar plantillas

```powershell
# Vista previa
.\install-templates.ps1 -Project 'D:\proyectos\mi-app' -WhatIf

# Crea solo las que falten (no sobrescribe nunca)
.\install-templates.ps1 -Project 'D:\proyectos\mi-app'
```

Copia `templates\*.template.md` a `.clinerules\<nombre>.md` y `.clineignore.template`
a `<proyecto>\.clineignore`. Si el fichero ya existe lo respeta (avisa con `=`); usa
`-Force` para sobrescribir. Después hay que **rellenar los `<huecos>`** a mano: son
esqueletos, no reglas listas.

## Actualizar un proyecto ya instalado

Vuelve a ejecutar el mismo comando: solo sobrescribirá lo que haya cambiado en el
kit, dejando backup del original. Los ficheros que hayas personalizado en el
proyecto se detectan como "distintos" → se respaldan antes de reemplazar.

## Añadir una regla nueva

1. Crea `rules/NN-nombre.md` aquí.
2. Mantenla genérica (sin rutas ni nombres de ese proyecto).
3. Reinstala en los proyectos que la necesiten.

Si la regla debe cargarse solo al tocar ciertos ficheros, añade frontmatter:

```yaml
---
paths:
  - "src/api/**"
---
```

Sin frontmatter, la regla se carga siempre.

## memory-bank

`memory-bank.md` asume que el proyecto tiene una carpeta `memory-bank/` con los 5
ficheros. Si el proyecto no la tiene, la regla lo indica y se ignora sola; no la
crea por su cuenta.

## Alternativa: ruta global

Cline también lee `C:\Users\<usuario>\.cline\rules`. **Ojo**: esas reglas se
aplican a *todos* los proyectos, incluidos los de producción, y las reglas del
proyecto ganan en caso de conflicto. Este kit está pensado para instalación por
proyecto precisamente por eso.

## Reglas vs. plantillas

| | `rules/` | `templates/` |
|---|---|---|
| Qué son | reglas terminadas | esqueletos con `<huecos>` |
| Contenido | genérico, válido para cualquier proyecto | estructura vacía a rellenar |
| Instalación | `install.ps1` (idempotente, backup al sobrescribir) | `install-templates.ps1` (no sobrescribe) |
| Ejemplos | 05-workflow, 30-review-workflow, memory-bank | 00-overview, 10-architecture, 20-testing |

Por qué la diferencia: `00-overview` y `10-architecture` hablan del stack y de las
clases de un proyecto concreto. Copiárselos a otro proyecto metería ruido
("existe BOT-FINAL-v47.py" dentro de un proyecto Django). Su parte reutilizable es
la *estructura*: secciones, orden y el frontmatter `paths:`, que hace que una regla
se cargue solo cuando el contexto toca esos ficheros.

## .clineignore

Reduce el contexto que Cline carga al arrancar una tarea (en proyectos grandes,
de cientos de miles de tokens a unas decenas de miles). La plantilla cubre lo
genérico: entornos, cachés, builds, secretos y datos grandes.

Dos avisos de la doc oficial:

1. **Está en vías de deprecación.** Cline dejará de soportarlo como
   característica. La alternativa recomendada es un hook `PreToolUse` que bloquea
   de verdad las lecturas y escrituras.
2. **No es control de acceso.** Ignorar un fichero evita que se cargue solo, pero
   se puede leer con `@mención` o desde la shell. Si necesitas blindaje real, hace
   falta el hook (bash + `jq` + `git`; en Windows implica Git Bash o WSL).

## Créditos

Basado en el flujo de trabajo de [vaibhav-space/my-ai-coding-workflow](https://github.com/vaibhav-space/my-ai-coding-workflow)
(plan → red-team → production readiness) y en las habilidades `ponytail`
(Dietrich Gebert) e `i-have-adhd` (ayghri), ambas MIT.
