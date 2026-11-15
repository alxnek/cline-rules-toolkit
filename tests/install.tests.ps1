# Pruebas de integracion sin modulos externos. Usar Windows PowerShell 5.1+.
$ErrorActionPreference = 'Stop'
$kit = Split-Path -Parent $PSScriptRoot
$root = Join-Path ([System.IO.Path]::GetTempPath()) ('cline-toolkit-tests-' + [guid]::NewGuid().ToString('N'))
$passed = 0

function Assert($condition, $message) {
    if (-not $condition) { throw "FALLO: $message" }
    $script:passed++
}
function Hash($path) { (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
function Snapshot($path) {
    $items = @(Get-ChildItem -LiteralPath $path -Recurse -Force -File | Sort-Object FullName)
    return (($items | ForEach-Object { $_.FullName.Substring($path.Length) + '=' + (Hash $_.FullName) }) -join "`n")
}
function MustThrow([scriptblock]$operation, $message) {
    $thrown = $false
    try { & $operation | Out-Null } catch { $thrown = $true }
    Assert $thrown $message
}

try {
    New-Item -ItemType Directory -Path $root | Out-Null
    $copy = Join-Path $root 'kit'
    $project = Join-Path $root 'proyecto con espacios'
    New-Item -ItemType Directory -Path $copy, $project | Out-Null
    Copy-Item -LiteralPath (Join-Path $kit 'rules'), (Join-Path $kit 'templates') -Destination $copy -Recurse
    Copy-Item -LiteralPath (Join-Path $kit 'install.ps1'), (Join-Path $kit 'install-templates.ps1') -Destination $copy
    $rules = Join-Path $copy 'install.ps1'
    $templates = Join-Path $copy 'install-templates.ps1'
    $target = Join-Path $project '.clinerules'
    $record = Join-Path $project '.clinerules-toolkit.json'
    $rule = Join-Path $target '05-workflow.md'
    $sourceRule = Join-Path $copy 'rules\05-workflow.md'

    $before = Snapshot $project
    & $rules -Project $project -WhatIf
    & $templates -Project $project -WhatIf
    Assert ((Snapshot $project) -eq $before) 'WhatIf no debe crear archivos ni carpetas'
    Assert (-not (Test-Path -LiteralPath $target)) 'WhatIf no debe crear .clinerules'

    & $rules -Project $project
    & $templates -Project $project
    Assert (Test-Path -LiteralPath $record -PathType Leaf) 'se crea el registro'
    Assert (Test-Path -LiteralPath (Join-Path $project '.clineignore') -PathType Leaf) 'se instala .clineignore'
    Assert ((Get-ChildItem -LiteralPath $target -File).Count -eq 6) 'se instalan tres reglas y tres plantillas'
    $before = Snapshot $project
    & $rules -Project $project
    & $templates -Project $project
    Assert ((Snapshot $project) -eq $before) 'segunda instalacion sin modificaciones'

    Add-Content -LiteralPath $sourceRule -Value 'Actualizacion del kit'
    $original = Hash $rule
    $before = Snapshot $project
    & $rules -Project $project -WhatIf
    Assert ((Snapshot $project) -eq $before) 'WhatIf no actualiza ni crea backup'
    & $rules -Project $project
    Assert ((Hash $rule) -eq (Hash $sourceRule)) 'actualizacion sin cambios locales'
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $project '.clinerules.bak') -Recurse -File -Filter '05-workflow.md')
    Assert ($backups.Count -eq 1 -and (Hash $backups[0].FullName) -eq $original) 'backup de regla actualizada'

    Add-Content -LiteralPath $rule -Value 'Personalizacion local'
    Add-Content -LiteralPath $sourceRule -Value 'Nueva actualizacion'
    $localHash = Hash $rule
    $before = Snapshot $project
    & $rules -Project $project
    Assert ((Hash $rule) -eq $localHash) 'se conserva modificacion local'
    Assert ((Snapshot $project) -eq $before) 'conflicto repetido sin escrituras'
    & $rules -Project $project -Files '05-workflow.md' -Force
    Assert ((Hash $rule) -eq (Hash $sourceRule)) 'Force reemplaza el conflicto seleccionado'
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $project '.clinerules.bak') -Recurse -File -Filter '05-workflow.md')
    Assert ($backups.Count -eq 2 -and @($backups | Where-Object { (Hash $_.FullName) -eq $localHash }).Count -eq 1) 'Force respalda la personalizacion sin colision'

    $overview = Join-Path $target '00-overview.md'
    $ignore = Join-Path $project '.clineignore'
    Set-Content -LiteralPath $overview -Value 'Plantilla personalizada'
    Set-Content -LiteralPath $ignore -Value 'ignore personalizado'
    $overviewHash = Hash $overview; $ignoreHash = Hash $ignore
    & $templates -Project $project
    Assert ((Hash $overview) -eq $overviewHash -and (Hash $ignore) -eq $ignoreHash) 'plantillas existentes preservadas'
    $before = Snapshot $project
    & $templates -Project $project -Files '00-overview.template.md','.clineignore.template' -Force -WhatIf
    Assert ((Snapshot $project) -eq $before) 'WhatIf con Force no reemplaza ni respalda plantillas'
    & $templates -Project $project -Files '00-overview.template.md','.clineignore.template' -Force
    $backupFiles = @(Get-ChildItem -LiteralPath (Join-Path $project '.clinerules.bak') -Recurse -File -Force)
    Assert (@($backupFiles | Where-Object { $_.Name -eq '00-overview.md' -and (Hash $_.FullName) -eq $overviewHash }).Count -eq 1) 'backup de plantilla'
    Assert (@($backupFiles | Where-Object { $_.Name -eq '.clineignore' -and (Hash $_.FullName) -eq $ignoreHash }).Count -eq 1) 'backup de .clineignore'

    $legacy = Join-Path $root 'legacy'
    New-Item -ItemType Directory -Path (Join-Path $legacy '.clinerules') -Force | Out-Null
    $legacyRule = Join-Path $legacy '.clinerules\05-workflow.md'
    Set-Content -LiteralPath $legacyRule -Value 'Regla previa'
    $legacyHash = Hash $legacyRule
    & $rules -Project $legacy
    Assert ((Hash $legacyRule) -eq $legacyHash) 'regla previa sin historial conservada'
    Assert (-not ((Get-Content -LiteralPath (Join-Path $legacy '.clinerules-toolkit.json') -Raw | ConvertFrom-Json).hashes.PSObject.Properties.Name -contains '05-workflow.md')) 'conflicto no se registra como gestionado'

    $adopt = Join-Path $root 'identico-sin-registro'
    New-Item -ItemType Directory -Path (Join-Path $adopt '.clinerules') -Force | Out-Null
    Copy-Item -LiteralPath $sourceRule -Destination (Join-Path $adopt '.clinerules\05-workflow.md')
    & $rules -Project $adopt -Files '05-workflow.md'
    $adoptRecord = Get-Content -LiteralPath (Join-Path $adopt '.clinerules-toolkit.json') -Raw | ConvertFrom-Json
    Assert ($adoptRecord.hashes.'05-workflow.md' -eq (Hash $sourceRule)) 'regla identica sin historial se registra'
    Assert (-not (Test-Path -LiteralPath (Join-Path $adopt '.clinerules.bak'))) 'adopcion identica no crea backup'

    $single = Join-Path $root 'archivo-clinerules'
    New-Item -ItemType Directory -Path $single | Out-Null
    Set-Content -LiteralPath (Join-Path $single '.clinerules') -Value 'reglas existentes'
    $before = Snapshot $single
    MustThrow { & $rules -Project $single } 'rechaza .clinerules como archivo'
    MustThrow { & $templates -Project $single } 'plantillas rechazan .clinerules como archivo'
    Assert ((Snapshot $single) -eq $before) 'archivo .clinerules conservado'

    $before = Snapshot $project
    MustThrow { & $rules -Project $project -Files '05-workflow.md','no-existe.md' } 'valida seleccion antes de escribir'
    MustThrow { & $templates -Project $project -Files '../escape.template.md' } 'rechaza rutas de plantillas'
    Assert ((Snapshot $project) -eq $before) 'selecciones invalidas no escriben'
    Set-Content -LiteralPath $record -Value '{ no es json'
    $before = Snapshot $project
    MustThrow { & $rules -Project $project } 'rechaza registro corrupto'
    Assert ((Snapshot $project) -eq $before) 'registro corrupto no provoca cambios'

    Write-Host "OK: $passed comprobaciones"
} finally {
    if (Test-Path -LiteralPath $root -PathType Container) {
        Remove-Item -LiteralPath $root -Recurse -Force
    }
}