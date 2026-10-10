param([int]$Size = 256)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$outputDirectory = Join-Path $PSScriptRoot "exports-$Size"
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

foreach ($file in (Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'a_*.png' -File)) {
    $source = [System.Drawing.Image]::FromFile($file.FullName)
    $target = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($target)
    try {
        $graphics.Clear([System.Drawing.Color]::Black)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($source, 0, 0, $Size, $Size)
        $target.Save((Join-Path $outputDirectory $file.Name), [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
        $graphics.Dispose()
        $target.Dispose()
        $source.Dispose()
    }
}

Write-Output "Exported $((Get-ChildItem -LiteralPath $outputDirectory -Filter 'a_*.png' -File).Count) icons at ${Size}x${Size}."
