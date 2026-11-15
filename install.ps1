<#
.SYNOPSIS
  Instala las reglas de cline-rules-toolkit en un proyecto.

.DESCRIPTION
  Copia los .md de .\rules a <Project>\.clinerules.
  - Si el destino no existe, lo crea.
  - Si el fichero es idéntico, lo salta (idempotente).
  - Si es distinto, hace backup en <Project>\.clinerules.bak\<timestamp>\ antes de copiar.
  - No borra nada del proyecto.

.EXAMPLE
  .\install.ps1 -Project 'D:\proyectos\mi-app'
  Instala todas las reglas del kit.

.EXAMPLE
  .\install.ps1 -Project 'D:\proyectos\mi-app' -WhatIf
  Muestra qué haría, sin tocar nada.

.EXAMPLE
  .\install.ps1 -Project 'D:\proyectos\mi-app' -Files 05-workflow.md,30-review-workflow.md
  Instala solo esas dos.

.EXAMPLE
  .\install.ps1 -Project 'D:\proyectos\mi-app' -Force
  Reemplaza aunque el contenido sea idéntico.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [string[]]$Files,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Source = Join-Path $PSScriptRoot 'rules'
$Target = Join-Path $Project '.clinerules'

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "No encuentro la carpeta de reglas: $Source"
}
if (-not (Test-Path -LiteralPath $Project -PathType Container)) {
    throw "El proyecto destino no existe: $Project"
}

if (-not $Files -or $Files.Count -eq 0) {
    $Files = Get-ChildItem -LiteralPath $Source -Filter '*.md' |
             Select-Object -ExpandProperty Name
}

$stamp     = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupRoot = Join-Path $Project (".clinerules.bak\$stamp")
$created   = 0
$updated   = 0
$skipped   = 0

if ($PSCmdlet.ShouldProcess($Target, "Crear .clinerules si no existe")) {
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
    }
}

Write-Host ""
Write-Host "Kit:  $Source"
Write-Host "Destino: $Target"
Write-Host ""

foreach ($name in $Files) {
    $src = Join-Path $Source $name
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Warning "  ! No existe en el kit: $name"
        continue
    }

    $dst = Join-Path $Target $name

    if (Test-Path -LiteralPath $dst -PathType Leaf) {
        $srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash

        if ($srcHash -eq $dstHash -and -not $Force) {
            Write-Host "  = $name (identico)"
            $skipped++
            continue
        }

        if ($PSCmdlet.ShouldProcess($dst, "Backup y reemplazar por $name")) {
            New-Item -ItemType Directory -Path (Split-Path -Parent (Join-Path $BackupRoot $name)) -Force | Out-Null
            Copy-Item -LiteralPath $dst -Destination (Join-Path $BackupRoot $name) -Force
            Copy-Item -LiteralPath $src -Destination $dst -Force
            Write-Host "  ~ $name (backup en .clinerules.bak\$stamp)"
            $updated++
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($dst, "Crear $name")) {
            Copy-Item -LiteralPath $src -Destination $dst
            Write-Host "  + $name"
            $created++
        }
    }
}

Write-Host ""
Write-Host "Creados: $created | Actualizados: $updated | Sin cambios: $skipped"
Write-Host ""

if ($WhatIfPreference) {
    Write-Host "Vista previa (-WhatIf): no se ha escrito nada."
}
