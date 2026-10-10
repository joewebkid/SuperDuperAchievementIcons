param(
    [int]$Size = 128,
    [long]$Quality = 80
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if ($Size -lt 64 -or $Quality -lt 1 -or $Quality -gt 100) {
    throw 'Size must be at least 64 and JPEG quality must be between 1 and 100.'
}

$sourceDirectory = Join-Path $PSScriptRoot 'exports-256'
$outputDirectory = Join-Path $PSScriptRoot 'exports-jpeg-128'
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

$encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
$parameters = [System.Drawing.Imaging.EncoderParameters]::new(1)
$parameters.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new(
    [System.Drawing.Imaging.Encoder]::Quality, $Quality
)

$files = @(Get-ChildItem -LiteralPath $sourceDirectory -Filter 'a_*.png' -File)
if ($files.Count -ne 92) { throw "Expected 92 source icons, found $($files.Count)." }

try {
    foreach ($file in $files) {
        $source = [System.Drawing.Image]::FromFile($file.FullName)
        $target = [System.Drawing.Bitmap]::new($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $graphics = [System.Drawing.Graphics]::FromImage($target)
        try {
            # JPEG has no alpha; the source icons have a black square background.
            $graphics.Clear([System.Drawing.Color]::Black)
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.DrawImage($source, 0, 0, $Size, $Size)
            $destination = Join-Path $outputDirectory ($file.BaseName + '.jpg')
            $target.Save($destination, $encoder, $parameters)
        } finally {
            $graphics.Dispose()
            $target.Dispose()
            $source.Dispose()
        }
    }
} finally {
    $parameters.Dispose()
}

Write-Output "Exported $($files.Count) JPEG icons at ${Size}x${Size}, quality $Quality."
