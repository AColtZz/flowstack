# bin/helpers/install-pma.ps1
$PmaVersion = "5.2.3"
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"

if (!(Test-Path $PmaFolder)) {
    Write-Host ">>> Downloading phpMyAdmin $PmaVersion..." -ForegroundColor Cyan
    $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
    $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
    $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

    Invoke-WebRequest -Uri $Url -OutFile $ZipPath

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempExtract)

    $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1
    Move-Item -Path $ExtractedFolder.FullName -Destination $PmaFolder

    # Config Template
    $Template = Join-Path $AppRoot "core\templates\pma-config.php"
    if (Test-Path $Template) {
        Copy-Item $Template -Destination (Join-Path $PmaFolder "config.inc.php") -Force
    }
    Remove-Item $ZipPath, $TempExtract -Recurse -ErrorAction SilentlyContinue
}