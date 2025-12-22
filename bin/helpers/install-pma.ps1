# bin/helpers/install-pma.ps1
$PmaVersion = "5.2.3"
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
# Points to the root of the extracted flowstack-main folder
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"

# Ensure the dashboard directory exists
$DashboardPath = Join-Path $AppRoot "core\dashboard"
if (!(Test-Path $DashboardPath)) {
    New-Item -ItemType Directory -Path $DashboardPath -Force | Out-Null
}

if (!(Test-Path $PmaFolder)) {
    Write-Host ">>> Downloading phpMyAdmin $PmaVersion..." -ForegroundColor Cyan
    $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
    $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
    $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

    Invoke-WebRequest -Uri $Url -OutFile $ZipPath

    # Modern PowerShell way to extract
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force

    $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1
    Move-Item -Path $ExtractedFolder.FullName -Destination $PmaFolder

    # Config Template
    $Template = Join-Path $AppRoot "core\templates\pma-config.php"
    if (Test-Path $Template) {
        Copy-Item $Template -Destination (Join-Path $PmaFolder "config.inc.php") -Force
        Write-Host ">>> phpMyAdmin configured via template." -ForegroundColor Gray
    }

    Remove-Item $ZipPath -Force
    Remove-Item $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ">>> phpMyAdmin installed successfully in core\dashboard." -ForegroundColor Green
}