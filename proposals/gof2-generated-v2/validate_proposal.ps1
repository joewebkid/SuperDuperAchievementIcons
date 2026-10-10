$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manifestPath = Join-Path $repositoryRoot 'games\www.fishlabs.net.gof2hd\1.1.4\manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$sourceDirectory = Join-Path $repositoryRoot 'games\www.fishlabs.net.gof2hd\1.1.4'
$expected = @($manifest.icons | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_.path) + '.png' })
$actual = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'a_*.png' -File | Select-Object -ExpandProperty Name)
$missing = @($expected | Where-Object { $_ -notin $actual })
$unexpected = @($actual | Where-Object { $_ -notin $expected })
$invalid = @()
$sourceMismatch = @()

foreach ($entry in $manifest.icons) {
    $sourcePath = Join-Path $sourceDirectory $entry.path
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        $sourceMismatch += $entry.path
        continue
    }
    $hash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { $sourceMismatch += $entry.path }
}

foreach ($name in $actual) {
    $path = Join-Path $PSScriptRoot $name
    $image = [System.Drawing.Image]::FromFile($path)
    try {
        if ($image.Width -ne $image.Height -or $image.Width -lt 256) {
            $invalid += "$name ($($image.Width)x$($image.Height))"
        }
    } finally {
        $image.Dispose()
    }
}

Write-Output "Expected: $($expected.Count); generated: $($actual.Count)"
Write-Output "Missing: $($missing.Count); unexpected: $($unexpected.Count); invalid dimensions: $($invalid.Count); source hash mismatch: $($sourceMismatch.Count)"
if ($missing.Count) { Write-Output ('Missing IDs: ' + ($missing -join ', ')) }
if ($unexpected.Count) { Write-Output ('Unexpected files: ' + ($unexpected -join ', ')) }
if ($invalid.Count) { Write-Output ('Invalid images: ' + ($invalid -join ', ')) }
if ($sourceMismatch.Count) { Write-Output ('Source mismatches: ' + ($sourceMismatch -join ', ')) }
if ($unexpected.Count -or $invalid.Count -or $sourceMismatch.Count) { exit 1 }
if ($missing.Count) { exit 2 }
