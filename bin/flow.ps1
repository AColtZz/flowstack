param([string]$Action)

# 1. Path Discovery
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent
$PersistDir = Join-Path (Split-Path $AppRoot -Parent) "persist\flowstack"

# Helper Function for PMA (so we can call it from anywhere)
function Ensure-PMA {
    $DashboardPath = Join-Path $AppRoot "core\dashboard"
    $PmaJunction = Join-Path $DashboardPath "phpmyadmin"

    if (!(Test-Path $PmaJunction)) {
        Write-Host ">>> phpMyAdmin not found. Installing..." -ForegroundColor Yellow
        $ZipPath = Join-Path $env:TEMP "pma_latest.zip"
        $TempExtract = Join-Path $env:TEMP "pma_extract"

        Invoke-WebRequest -Uri "https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip" -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force

        $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1
        $DestinationPath = Join-Path $DashboardPath $ExtractedFolder.Name

        if (!(Test-Path $DestinationPath)) { Move-Item -Path $ExtractedFolder.FullName -Destination $DestinationPath }
        New-Item -ItemType Junction -Path $PmaJunction -Target $DestinationPath -Force | Out-Null

        $Template = Join-Path $AppRoot "core\templates\pma-config.php"
        if (Test-Path $Template) { Copy-Item $Template -Destination (Join-Path $PmaJunction "config.inc.php") -Force }

        Remove-Item $ZipPath -ErrorAction SilentlyContinue
        Remove-Item $TempExtract -Recurse -ErrorAction SilentlyContinue
        Write-Host ">>> phpMyAdmin Ready!" -ForegroundColor Green
    }
}

# 2. Command Router
switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Initializing..." -ForegroundColor Cyan

        # Ensure PMA is ready before starting
        Ensure-PMA

        # Setup Paths & Config
        $PhpDir = Split-Path (Get-Command php).Source
        $ExtDir = Join-Path $PhpDir "ext"
        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        # Junction for htdocs
        $HtdocsLink = Join-Path $AppRoot "core\dashboard\htdocs"
        $ActualHtdocs = Join-Path $PersistDir "htdocs"
        if (!(Test-Path $ActualHtdocs)) { New-Item -ItemType Directory -Path $ActualHtdocs -Force | Out-Null }
        if (!(Test-Path $HtdocsLink)) { New-Item -ItemType Junction -Path $HtdocsLink -Target $ActualHtdocs }

        # Start Services
        Write-Host ">>> Starting MariaDB & PHP Server..." -ForegroundColor Gray
        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        $PhpArgs = @("-S", "localhost:8888", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"", "-d", "extension_dir=`"$ExtDir`"")
        Start-Process php -ArgumentList $PhpArgs -WindowStyle Hidden

        Write-Host ">>> FlowStack is UP at http://localhost:8888" -ForegroundColor Green
        Start-Process "http://localhost:8888"
    }

    "down" {
        Write-Host ">>> FlowStack: Shutting down services..." -ForegroundColor Red
        # Kill by name, but we also search for the specific processes to be sure
        Get-Process php, mysqld -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host ">>> All services stopped." -ForegroundColor Gray
    }

    "new" {
        & "$PSScriptPath\helpers\new-site.ps1"
    }

    Default {
        Write-Host "Usage: flow [up | down | new]" -ForegroundColor White
    }
}