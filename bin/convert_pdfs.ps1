# Конвертирует все PDF-файлы из data_sources/pdf/ в текстовые файлы (data_sources/txt/)
# Используется библиотека pdftotext из poppler-utils

$pdftotext = "C:\Users\User\AppData\Local\Temp\poppler\poppler-24.02.0\Library\bin\pdftotext.exe"

# Проверка наличия pdftotext
if (-not (Test-Path -Path $pdftotext)) {
    Write-Error "pdftotext.exe не найден по пути: $pdftotext"
    Write-Output "Скачайте poppler для Windows: https://github.com/oschwartz10612/poppler-windows/releases/"
    exit 1
}

$root = Join-Path $PSScriptRoot ".."
$pdfRoot = Join-Path $root "data_sources\pdf"
$txtRoot = Join-Path $root "data_sources\txt"

# Создаём все выходные папки заранее
New-Item -ItemType Directory -Path "$txtRoot\scores"    -Force | Out-Null
New-Item -ItemType Directory -Path "$txtRoot\admission" -Force | Out-Null
New-Item -ItemType Directory -Path "$txtRoot\dormitory" -Force | Out-Null

Write-Output "=== Конвертация PDF -> TXT ==="

# --- 1. Проходные баллы прошлых лет (data_sources/pdf/scores/) ---
$scoresIn  = Join-Path $pdfRoot "scores"
$scoresOut = Join-Path $txtRoot "scores"
Write-Output "`n[scores] $scoresIn -> $scoresOut"
Get-ChildItem -Path $scoresIn -Filter "*.pdf" | Sort-Object Name | ForEach-Object {
    $outFile = Join-Path $scoresOut ($_.BaseName + ".txt")
    & $pdftotext -layout -enc UTF-8 $_.FullName $outFile
    Write-Output "  Converted: $($_.Name)"
}

# --- 2. Документы приёмной кампании (data_sources/pdf/admission/) ---
$admIn  = Join-Path $pdfRoot "admission"
$admOut = Join-Path $txtRoot "admission"
New-Item -ItemType Directory -Path $admOut -Force | Out-Null
Write-Output "`n[admission] $admIn -> $admOut"
Get-ChildItem -Path $admIn -Filter "*.pdf" | Sort-Object Name | ForEach-Object {
    $outFile = Join-Path $admOut ($_.BaseName + ".txt")
    & $pdftotext -layout -enc UTF-8 $_.FullName $outFile
    Write-Output "  Converted: $($_.Name)"
}

# --- 3. Вместимость общежитий (data_sources/pdf/dormitory/) ---
$dormIn  = Join-Path $pdfRoot "dormitory"
$dormOut = Join-Path $txtRoot "dormitory"
New-Item -ItemType Directory -Path $dormOut -Force | Out-Null
Write-Output "`n[dormitory] $dormIn -> $dormOut"
Get-ChildItem -Path $dormIn -Filter "*.pdf" | Sort-Object Name | ForEach-Object {
    $outFile = Join-Path $dormOut ($_.BaseName + ".txt")
    & $pdftotext -layout -enc UTF-8 $_.FullName $outFile
    Write-Output "  Converted: $($_.Name)"
}

# --- 4. Минимальные баллы ЕГЭ (data_sources/pdf/min_balls.pdf) ---
$minBallsPdf = Join-Path $pdfRoot "min_balls.pdf"
$minBallsTxt = Join-Path $txtRoot "min_balls.txt"
if (Test-Path $minBallsPdf) {
    Write-Output "`n[min_balls] $minBallsPdf -> $minBallsTxt"
    & $pdftotext -layout -enc UTF-8 $minBallsPdf $minBallsTxt
    Write-Output "  Converted: min_balls.pdf"
}

Write-Output "`n=== Готово! Все файлы сконвертированы в data_sources/txt/ ==="
