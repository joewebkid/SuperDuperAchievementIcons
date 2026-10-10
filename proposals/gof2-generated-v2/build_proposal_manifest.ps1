$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$originalPath = Join-Path $repositoryRoot 'games\www.fishlabs.net.gof2hd\1.1.4\manifest.json'
$original = Get-Content -LiteralPath $originalPath -Raw | ConvertFrom-Json
$icons = @()

foreach ($entry in $original.icons) {
    $fileName = [IO.Path]::GetFileNameWithoutExtension($entry.path) + '.jpg'
    $filePath = Join-Path $PSScriptRoot (Join-Path 'exports-jpeg-128' $fileName)
    if (-not (Test-Path -LiteralPath $filePath)) { throw "Missing export: $fileName" }
    $file = Get-Item -LiteralPath $filePath
    $icons += [ordered]@{
        gameCenterId = $entry.gameCenterId
        title = $entry.title
        path = "exports-jpeg-128/$fileName"
        sha256 = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
        bytes = $file.Length
        referenceSourceUrl = $entry.sourceUrl
    }
}

$proposal = [ordered]@{
    formatVersion = 1
    artRevision = 'generated-v2-draft'
    bundleId = $original.bundleId
    bundleVersion = $original.bundleVersion
    executableSha256 = $original.executableSha256
    icons = $icons
}

$proposal | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Encoding utf8
Write-Output "Wrote proposal manifest with $($icons.Count) icons."
