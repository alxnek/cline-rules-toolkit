<#
.SYNOPSIS
  Instala y actualiza reglas sin reemplazar cambios locales por defecto.
.DESCRIPTION
  Registra los hashes instalados en .clinerules-toolkit.json. Actualiza una regla
  solo si coincide con la ultima version registrada; los conflictos se respetan.
  -Force reemplaza conflictos con backup. -WhatIf no escribe nada.
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
if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "No existe la carpeta de reglas: $Source" }
if (-not (Test-Path -LiteralPath $Project -PathType Container)) { throw "El proyecto destino no existe: $Project" }
$Project = (Resolve-Path -LiteralPath $Project).ProviderPath
$Target = Join-Path $Project '.clinerules'
$Manifest = Join-Path $Project '.clinerules-toolkit.json'
if ((Test-Path -LiteralPath $Target) -and -not (Test-Path -LiteralPath $Target -PathType Container)) {
    throw "El destino .clinerules no es una carpeta. Conserva el archivo y resuelve la migracion manualmente: $Target"
}
if ((Test-Path -LiteralPath $Manifest) -and -not (Test-Path -LiteralPath $Manifest -PathType Leaf)) {
    throw "El registro no es un archivo: $Manifest"
}

$hashes = @{}
if (Test-Path -LiteralPath $Manifest -PathType Leaf) {
    try { $data = Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json }
    catch { throw "No se puede leer el registro $Manifest. No se ha modificado nada. $_" }
    if ($null -eq $data -or $data.version -ne 1 -or $null -eq $data.hashes -or $data.hashes -isnot [PSCustomObject]) {
        throw "Registro invalido o version no compatible: $Manifest"
    }
    foreach ($entry in $data.hashes.PSObject.Properties) {
        if ($entry.Name -notmatch '^[^\\/:]+\.md$' -or $entry.Value -notmatch '^[A-Fa-f0-9]{64}$') {
            throw "Entrada invalida en el registro: $($entry.Name)"
        }
        $hashes[$entry.Name] = $entry.Value
    }
}

if (-not $Files -or $Files.Count -eq 0) {
    $Files = @(Get-ChildItem -LiteralPath $Source -File -Filter '*.md' | Sort-Object Name | Select-Object -ExpandProperty Name)
}
# Validar toda la seleccion antes de escribir, incluidas rutas y colisiones.
foreach ($name in $Files) {
    if ($name -notmatch '^[^\\/:]+\.md$') { throw "Nombre de regla invalido: $name" }
    if (-not (Test-Path -LiteralPath (Join-Path $Source $name) -PathType Leaf)) { throw "No existe en el kit: $name" }
    $dst = Join-Path $Target $name
    if ((Test-Path -LiteralPath $dst) -and -not (Test-Path -LiteralPath $dst -PathType Leaf)) { throw "El destino no es un archivo: $dst" }
}

$counts = @{ Created = 0; Updated = 0; Same = 0; Conflict = 0 }
$manifestChanged = $false
$manifestPlanned = $false
$backupRoot = Join-Path $Project ('.clinerules.bak\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
Write-Host "Kit: $Source`nDestino: $Target"
foreach ($name in $Files) {
    $src = Join-Path $Source $name
    $dst = Join-Path $Target $name
    $sourceHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
    $action = 'Create'
    if (Test-Path -LiteralPath $dst -PathType Leaf) {
        $destHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
        if ($destHash -eq $sourceHash) { $action = 'Same' }
        elseif ($Force -or ($hashes.ContainsKey($name) -and $destHash -eq $hashes[$name])) { $action = 'Update' }
        else { $action = 'Conflict' }
    }
    switch ($action) {
        'Same' {
            Write-Host "  = $name (identico)"
            $counts.Same++
            if (-not $hashes.ContainsKey($name) -or $hashes[$name] -ne $sourceHash) { $hashes[$name] = $sourceHash; $manifestChanged = $true }
        }
        'Conflict' {
            Write-Warning "  ! $name (diferente o sin historial; se conserva y requiere revision)"
            $counts.Conflict++
        }
        'Create' {
            $counts.Created++
            $manifestPlanned = $true
            if ($PSCmdlet.ShouldProcess($dst, 'Crear regla')) {
                if (-not (Test-Path -LiteralPath $Target -PathType Container)) { New-Item -ItemType Directory -Path $Target | Out-Null }
                Copy-Item -LiteralPath $src -Destination $dst
                Write-Host "  + $name"
                $hashes[$name] = $sourceHash; $manifestChanged = $true
            }
        }
        'Update' {
            $counts.Updated++
            $manifestPlanned = $true
            if ($PSCmdlet.ShouldProcess($dst, 'Respaldar y actualizar regla')) {
                New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
                Copy-Item -LiteralPath $dst -Destination (Join-Path $backupRoot $name)
                Copy-Item -LiteralPath $src -Destination $dst -Force
                Write-Host "  ~ $name (backup: $backupRoot)"
                $hashes[$name] = $sourceHash; $manifestChanged = $true
            }
        }
    }
}
if (($manifestChanged -or ($WhatIfPreference -and $manifestPlanned)) -and $PSCmdlet.ShouldProcess($Manifest, 'Guardar hashes de reglas gestionadas')) {
    $record = [ordered]@{ version = 1; hashes = $hashes }
    $record | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Manifest -Encoding UTF8
}
$label = if ($WhatIfPreference) { 'Previstos' } else { 'Procesados' }
Write-Host "${label}: crear $($counts.Created) | actualizar $($counts.Updated) | iguales $($counts.Same) | conflictos $($counts.Conflict)"
if ($WhatIfPreference) { Write-Host 'Vista previa: no se ha escrito nada.' }