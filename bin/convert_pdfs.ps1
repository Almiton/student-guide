$pdftotext = "C:\Users\User\AppData\Local\Temp\poppler\poppler-24.02.0\Library\bin\pdftotext.exe"
$pdfDir = Join-Path $PSScriptRoot "..\PDF"
$outDir = Join-Path $PSScriptRoot "..\PDF_text"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

if (-not (Test-Path -Path $pdfDir)) {
    Write-Output "PDF directory '$pdfDir' not found. Nothing to convert."
    exit 0
}

Get-ChildItem -Path $pdfDir -Filter "*.pdf" | Sort-Object Name | ForEach-Object {
    $outFile = Join-Path $outDir ($_.BaseName + ".txt")
    & $pdftotext -layout -enc UTF-8 $_.FullName $outFile
    Write-Output "Converted: $($_.Name) -> $outFile"
}
Write-Output "Done!"
