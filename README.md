# cline-rules-toolkit

Reglas de ingeniería para Cline, reutilizables entre proyectos. Fuente única de
verdad: se editan aquí y se instalan en cada proyecto con `install.ps1`.

## Inicio rápido (con un agente de Cline)

Copia este prompt en una tarea de Cline abierta en la **raíz del proyecto** donde
quieras las reglas. Requiere Git y Windows PowerShell. El agente inspecciona primero
el proyecto; no debe sustituir ni editar reglas personalizadas sin tu autorización:

```text
Instala y configura cline-rules-toolkit en la raíz de este proyecto.
Fuente: https://github.com/alxnek/cline-rules-toolkit.git. Idioma: español.
Usa PowerShell en Windows y sigue este procedimiento:

1. Identifica la raíz absoluta del proyecto y revisa git status, si existe Git.
   Inventaría y lee las reglas existentes de .clinerules, .cline/rules,
   AGENTS.md, .cursorrules y .windsurfrules; revisa también .clineignore.
   No imprimas secretos ni modifiques reglas globales. Si .clinerules es un
   archivo y no una carpeta, detente y pide una decisión de migración.
2. Clona el kit fuera del proyecto en una carpeta temporal nueva y única:
   $kit = Join-Path $env:TEMP ("cline-rules-toolkit-" + [guid]::NewGuid().ToString('N'))
   git clone https://github.com/alxnek/cline-rules-toolkit.git $kit
   Si falla el clon, detente. No borres ni reutilices carpetas existentes.
3. Lee las reglas y plantillas del kit. Compara su contenido con las reglas
   existentes, aunque tengan nombres diferentes. Si hay contradicciones o
   dudas, presenta los conflictos y pide una decisión antes de modificar nada.
   No dupliques reglas que contradigan las existentes ni asumas su prioridad.
4. Ejecuta ambas vistas previas antes de instalar, con la raíz absoluta:
   & "$kit\install.ps1" -Project "<raíz de este proyecto>" -WhatIf
   & "$kit\install-templates.ps1" -Project "<raíz de este proyecto>" -WhatIf
   Si aparece un conflicto, no uses -Force; explica el problema y pide decisión.
   Si los resultados son seguros, ejecuta ambos comandos sin -WhatIf ni -Force.
   Detente si hay errores. Si la política bloquea scripts, usa, para cada uno:
   powershell -ExecutionPolicy Bypass -File "<ruta absoluta al script>" -Project "<raíz de este proyecto>" -WhatIf
   Solo después de revisar ambas vistas previas, repite sin -WhatIf.
5. Rellena SOLO las plantillas .md creadas en esta ejecución con datos reales
   comprobados del proyecto; no inventes comandos. Si falta información, indica
   el dato pendiente. No edites plantillas o .clineignore preexistentes.
6. Comprueba los archivos resultantes, los conflictos, el estado de Git y, en el
   panel de reglas de Cline, que las reglas necesarias estén activadas. Resume
   creados, actualizados, respetados, backups y pendientes. Indica los conflictos
   sin resolver y no declares la instalación completamente operativa si los hay.
```

`<raíz de este proyecto>` = ruta absoluta del proyecto destino, no la carpeta del kit.
La revisión semántica requiere criterio del agente y, si existe un conflicto, una
decisión del usuario: los scripts no pueden detectar contradicciones por contenido.

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
├── install-templates.ps1         # instala templates/
└── tests/install.tests.ps1        # pruebas sin dependencias adicionales
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
| fichero idéntico | lo respeta y registra su hash (`=`) |
| fichero distinto, sin cambios locales desde la última instalación registrada | backup y actualización (`~`) |
| fichero distinto, con cambios locales o sin historial | lo conserva y avisa del conflicto (`!`) |
| conflicto con `-Force` explícito | backup y reemplazo (`~`) |

El registro `<proyecto>\.clinerules-toolkit.json` guarda hashes SHA-256 de las
reglas gestionadas. Consérvalo en el repositorio junto a las reglas para compartir
el historial. Si se pierde, los archivos diferentes se tratan como conflictos.
Los backups se guardan en `<proyecto>\.clinerules.bak\<timestamp>-<id>\`.
No se borran reglas; el registro y los backups se crean fuera de `.clinerules`.
Revisa el `.gitignore` del proyecto destino para excluir `.clinerules.bak/` si
no deseas publicar backups; podrían contener información sensible preexistente.
Si `.clinerules` es un archivo, el instalador se detiene sin migrarlo ni modificarlo.
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
`-Force` para sobrescribir explícitamente con backup. Después hay que **rellenar los `<huecos>`** a mano: son
esqueletos, no reglas listas.

## Actualizar un proyecto ya instalado

Ejecuta primero ambos scripts con `-WhatIf`. Las reglas gestionadas sin cambios
locales se actualizan con backup; las personalizadas se conservan y se notifican
como conflictos. Las plantillas ya existentes no se actualizan. Examina las
diferencias antes de resolver cada conflicto; usa `-Files` para seleccionar reglas
y `-Force` solo si se ha autorizado expresamente su reemplazo. Una mezcla manual
requiere revisión: el instalador no fusiona contenido ni verifica coherencia semántica.

## Pruebas del instalador

Desde la carpeta del kit ejecuta `powershell -NoProfile -File .\tests\install.tests.ps1`.
Las pruebas crean y limpian proyectos aislados dentro de una carpeta temporal única.

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

Cline también lee reglas globales, por defecto en `Documents\Cline\Rules` en Windows
(y busca otras ubicaciones, incluida `~\.cline\rules`). **Ojo**: esas reglas se
aplican a *todos* los proyectos, incluidos los de producción, y las reglas del
proyecto ganan en caso de conflicto. Este kit está pensado para instalación por
proyecto precisamente por eso.

## Reglas vs. plantillas

| | `rules/` | `templates/` |
|---|---|---|
| Qué son | reglas terminadas | esqueletos con `<huecos>` |
| Contenido | genérico, válido para cualquier proyecto | estructura vacía a rellenar |
| Instalación | `install.ps1` (conserva cambios locales; backup al actualizar) | `install-templates.ps1` (conserva existentes por defecto) |
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
