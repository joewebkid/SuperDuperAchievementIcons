$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceDirectory = Join-Path $repositoryRoot 'games\www.fishlabs.net.gof2hd\1.1.4'
$sourceManifest = Get-Content -LiteralPath (Join-Path $sourceDirectory 'manifest.json') -Raw | ConvertFrom-Json
$proposalManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw | ConvertFrom-Json
$exportDirectory = Join-Path $PSScriptRoot 'exports-jpeg-128'
$expected = @($sourceManifest.icons | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.path) + '.jpg' })
$exports = @(Get-ChildItem -LiteralPath $exportDirectory -Filter 'a_*.jpg' -File | Select-Object -ExpandProperty Name)
$masters = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'a_*.png' -File | Select-Object -ExpandProperty Name)
$missing = @($expected | Where-Object { $_ -notin $exports })
$unexpected = @($exports | Where-Object { $_ -notin $expected })
$invalid = @()
$hashMismatch = @()
$sourceMismatch = @()

if ($masters.Count -gt 0) {
    $expectedMasters = @($sourceManifest.icons | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.path) + '.png' })
    $missing += @($expectedMasters | Where-Object { $_ -notin $masters })
    $unexpected += @($masters | Where-Object { $_ -notin $expectedMasters })
}

foreach ($entry in $sourceManifest.icons) {
    $sourcePath = Join-Path $sourceDirectory $entry.path
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        $sourceMismatch += $entry.path
        continue
    }
    $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { $sourceMismatch += $entry.path }
}

if ($proposalManifest.icons.Count -ne $expected.Count) {
    $hashMismatch += "manifest icon count $($proposalManifest.icons.Count)"
}

foreach ($sourceEntry in $sourceManifest.icons) {
    $matching = @($proposalManifest.icons | Where-Object { $_.gameCenterId -eq $sourceEntry.gameCenterId })
    $expectedPath = 'exports-jpeg-128/' + [IO.Path]::GetFileNameWithoutExtension($sourceEntry.path) + '.jpg'
    if ($matching.Count -ne 1 -or $matching[0].title -ne $sourceEntry.title -or $matching[0].path -ne $expectedPath) {
        $hashMismatch += $sourceEntry.gameCenterId
    }
}

foreach ($entry in $proposalManifest.icons) {
    $exportPath = Join-Path $PSScriptRoot $entry.path
    if (-not (Test-Path -LiteralPath $exportPath)) {
        $hashMismatch += $entry.path
        continue
    }
    $file = Get-Item -LiteralPath $exportPath
    $hash = (Get-FileHash -LiteralPath $exportPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256 -or $file.Length -ne $entry.bytes) {
        $hashMismatch += $entry.path
    }
}

foreach ($name in $exports) {
    $image = [System.Drawing.Image]::FromFile((Join-Path $exportDirectory $name))
    try {
        if ($image.Width -ne 128 -or $image.Height -ne 128) { $invalid += "export $name" }
    } finally { $image.Dispose() }
}

foreach ($name in $masters) {
    $image = [System.Drawing.Image]::FromFile((Join-Path $PSScriptRoot $name))
    try {
        if ($image.Width -ne $image.Height -or $image.Width -lt 256) { $invalid += "master $name" }
    } finally { $image.Dispose() }
}

Write-Output "Expected: $($expected.Count); exported: $($exports.Count); local masters: $($masters.Count)"
Write-Output "Missing: $($missing.Count); unexpected: $($unexpected.Count); invalid dimensions: $($invalid.Count); export hash mismatch: $($hashMismatch.Count); source hash mismatch: $($sourceMismatch.Count)"
if ($missing.Count) { Write-Output ('Missing IDs: ' + ($missing -join ', ')) }
if ($unexpected.Count) { Write-Output ('Unexpected files: ' + ($unexpected -join ', ')) }
if ($invalid.Count) { Write-Output ('Invalid images: ' + ($invalid -join ', ')) }
if ($hashMismatch.Count) { Write-Output ('Export mismatches: ' + ($hashMismatch -join ', ')) }
if ($sourceMismatch.Count) { Write-Output ('Source mismatches: ' + ($sourceMismatch -join ', ')) }
if ($unexpected.Count -or $invalid.Count -or $hashMismatch.Count -or $sourceMismatch.Count) { exit 1 }
if ($missing.Count) { exit 2 }
