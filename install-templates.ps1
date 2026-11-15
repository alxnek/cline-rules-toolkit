<#
.SYNOPSIS
  Instala las plantillas de cline-rules-toolkit en un proyecto.

.DESCRIPTION
  Copia los ficheros de .\templates a un proyecto:
    - *.template.md   -> <Project>\.clinerules\<nombre>.md
    - *.template      -> <Project>\.clineignore   (si empieza por punto)

  A diferencia de install.ps1, por defecto NO sobrescribe: si el fichero ya
  existe se salta y avisa (son esqueletos pensados para rellenar a mano).
  Usa -Force para sobrescribir.

.EXAMPLE
  .\install-templates.ps1 -Project 'D:\proyectos\mi-app' -WhatIf
  Vista previa sin escribir.

.EXAMPLE
  .\install-templates.ps1 -Project 'D:\proyectos\mi-app'
  Crea las plantillas que falten.

.EXAMPLE
  .\install-templates.ps1 -Project 'D:\proyectos\mi-app' -Files '20-testing.template.md'
  Solo una plantilla.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [string[]]$Files,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Source = Join-Path $PSScriptRoot 'templates'
$Target = Join-Path $Project '.clinerules'

if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "No encuentro la carpeta templates en el kit: $Source"
}
if (-not (Test-Path -LiteralPath $Project -PathType Container)) {
    throw "El proyecto destino no existe: $Project"
}

if (-not $Files -or $Files.Count -eq 0) {
    $Files = Get-ChildItem -LiteralPath $Source -File | Select-Object -ExpandProperty Name
}

if ($PSCmdlet.ShouldProcess($Target, "Crear .clinerules si no existe")) {
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        New-Item -ItemType Directory -Path $Target -Force | Out-Null
    }
}

Write-Host ""
Write-Host "Plantillas: $Source"
Write-Host "Destino:    $Project"
Write-Host ""

$created = 0
$skipped = 0
$forced  = 0

foreach ($name in $Files) {
    $src = Join-Path $Source $name
    if (-not (Test-Path -LiteralPath $src -PathType Leaf)) {
        Write-Warning "  ! No existe en el kit: $name"
        continue
    }

    $destName = $name -replace '\.template\.md$', '.md'
    $destName = $destName -replace '\.template$', ''

    if ($destName.StartsWith('.')) {
        $dst = Join-Path $Project $destName
    }
    else {
        $dst = Join-Path $Target $destName
    }

    if ((Test-Path -LiteralPath $dst -PathType Leaf) -and -not $Force) {
        Write-Host "  = $destName (ya existe, se respeta)"
        $skipped++
        continue
    }

    if ($PSCmdlet.ShouldProcess($dst, "Crear plantilla $destName")) {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        if (Test-Path -LiteralPath $dst -PathType Leaf) { Write-Host "  + $destName"; $created++ }
    }
}

Write-Host ""
Write-Host "Creadas: $created | Respetadas: $skipped"
Write-Host ""
Write-Host "Recuerda: son esqueletos. Rellena los <huecos> antes de usarlos."
Write-Host ""
