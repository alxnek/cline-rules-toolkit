<#
.SYNOPSIS
  Instala las plantillas que faltan; -Force respalda antes de reemplazar.
.DESCRIPTION
  -WhatIf muestra las operaciones sin escribir. Las plantillas existentes se
  conservan por defecto, incluida .clineignore.
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
if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "No existe la carpeta de plantillas: $Source" }
if (-not (Test-Path -LiteralPath $Project -PathType Container)) { throw "El proyecto destino no existe: $Project" }
$Project = (Resolve-Path -LiteralPath $Project).ProviderPath
$Target = Join-Path $Project '.clinerules'
if ((Test-Path -LiteralPath $Target) -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
    throw "El destino .clinerules no es una carpeta. Resuelve la migracion manualmente: $Target"
}
if (-not $Files -or $Files.Count -eq 0) {
    $Files = @(Get-ChildItem -LiteralPath $Source -File -Force | Sort-Object Name | Select-Object -ExpandProperty Name)
}
$items = @(
    foreach ($name in $Files) {
        if ($name -notmatch '^[^\\/:]+\.template(\.md)?$') { throw "Nombre de plantilla invalido: $name" }
        $src = Join-Path $Source $name
        if (-not (Test-Path -LiteralPath $src -PathType Leaf)) { throw "No existe en el kit: $name" }
        $destName = ($name -replace '\.template\.md$', '.md') -replace '\.template$', ''
        $dst = if ($destName.StartsWith('.')) { Join-Path $Project $destName } else { Join-Path $Target $destName }
        if ((Test-Path -LiteralPath $dst) -and -not (Test-Path -LiteralPath $dst -PathType Leaf)) { throw "El destino no es un archivo: $dst" }
        [PSCustomObject]@{ Name = $destName; Source = $src; Destination = $dst }
    }
)
$backupRoot = Join-Path $Project ('.clinerules.bak\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
$counts = @{ Created = 0; Updated = 0; Same = 0; Preserved = 0 }
Write-Host "Plantillas: $Source`nDestino: $Project"
foreach ($item in $items) {
    $exists = Test-Path -LiteralPath $item.Destination -PathType Leaf
    if ($exists -and -not $Force) {
        Write-Host "  = $($item.Name) (ya existe, se respeta)"
        $counts.Preserved++; continue
    }
    if ($exists -and (Get-FileHash -LiteralPath $item.Source -Algorithm SHA256).Hash -eq (Get-FileHash -LiteralPath $item.Destination -Algorithm SHA256).Hash) {
        Write-Host "  = $($item.Name) (identica)"
        $counts.Same++; continue
    }
    if ($exists) { $counts.Updated++; $action = 'Respaldar y reemplazar plantilla' }
    else { $counts.Created++; $action = 'Crear plantilla' }
    if ($PSCmdlet.ShouldProcess($item.Destination, $action)) {
        if ($exists) {
            $backupDir = if ($item.Name.StartsWith('.')) { Join-Path $backupRoot 'root' } else { Join-Path $backupRoot '.clinerules' }
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item -LiteralPath $item.Destination -Destination (Join-Path $backupDir $item.Name)
            Write-Host "  ~ $($item.Name) (backup: $backupDir)"
        } else {
            $parent = Split-Path -Parent $item.Destination
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent | Out-Null }
            Write-Host "  + $($item.Name)"
        }
        Copy-Item -LiteralPath $item.Source -Destination $item.Destination -Force
    }
}
$label = if ($WhatIfPreference) { 'Previstas' } else { 'Procesadas' }
Write-Host "${label}: crear $($counts.Created) | reemplazar $($counts.Updated) | iguales $($counts.Same) | respetadas $($counts.Preserved)"
if ($WhatIfPreference) { Write-Host 'Vista previa: no se ha escrito nada.' }