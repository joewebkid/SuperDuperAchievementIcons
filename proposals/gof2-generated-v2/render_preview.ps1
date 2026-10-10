param(
    [int]$IconSize = 64,
    [int]$Columns = 8
)

Add-Type -AssemblyName System.Drawing

$files = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'a_*.png' -File | Sort-Object Name)
if ($files.Count -eq 0) { throw 'No generated icons found.' }

$cellWidth = $IconSize + 28
$cellHeight = $IconSize + 34
$rows = [int][Math]::Ceiling($files.Count / $Columns)
$preview = [System.Drawing.Bitmap]::new($Columns * $cellWidth, $rows * $cellHeight)
$graphics = [System.Drawing.Graphics]::FromImage($preview)
$font = [System.Drawing.Font]::new('Arial', 8)
$brush = [System.Drawing.Brushes]::White

try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(15, 22, 32))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($index = 0; $index -lt $files.Count; $index++) {
        $image = [System.Drawing.Image]::FromFile($files[$index].FullName)
        try {
            $column = $index % $Columns
            $row = [int][Math]::Floor($index / $Columns)
            $x = $column * $cellWidth + 14
            $y = $row * $cellHeight + 6
            $graphics.DrawImage($image, $x, $y, $IconSize, $IconSize)
            $label = $files[$index].BaseName.Replace('a_', '').Replace('_', ' ')
            if ($label.Length -gt 14) { $label = $label.Substring(0, 14) }
            $graphics.DrawString($label, $font, $brush, $column * $cellWidth + 3, $y + $IconSize + 2)
        } finally {
            $image.Dispose()
        }
    }
    $preview.Save((Join-Path $PSScriptRoot 'preview-64.png'), [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $graphics.Dispose()
    $font.Dispose()
    $preview.Dispose()
}
