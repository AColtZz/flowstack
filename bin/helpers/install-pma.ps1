# bin/helpers/install-pma.ps1
$PmaVersion = "5.2.3"
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"

# Ensure the dashboard directory exists
$DashboardPath = Join-Path $AppRoot "core\dashboard"
if (!(Test-Path $DashboardPath)) {
    New-Item -ItemType Directory -Path $DashboardPath -Force | Out-Null
}

# IMPORTANT: Check if index.php exists.
# Because Scoop creates a "Junction" folder, Test-Path $PmaFolder will ALWAYS be true.
if (!(Test-Path (Join-Path $PmaFolder "index.php"))) {
    Write-Host ">>> phpMyAdmin not found in persistent storage. Installing..." -ForegroundColor Cyan

    $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
    $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
    $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

    Invoke-WebRequest -Uri $Url -OutFile $ZipPath

    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force

    $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1

    # Move files INTO the junctioned folder
    Copy-Item -Path "$($ExtractedFolder.FullName)\*" -Destination $PmaFolder -Recurse -Force

    # Config Template
    $Template = Join-Path $AppRoot "core\templates\pma-config.php"
    if (Test-Path $Template) {
        Copy-Item $Template -Destination (Join-Path $PmaFolder "config.inc.php") -Force
        Write-Host ">>> phpMyAdmin configured via template." -ForegroundColor Gray
    }

    Remove-Item $ZipPath -Force
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ">>> phpMyAdmin installed successfully!" -ForegroundColor Green
} else {
    Write-Host ">>> phpMyAdmin is already present in persistent storage." -ForegroundColor Gray
}