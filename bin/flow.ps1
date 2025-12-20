param([string]$Action)

# --- Configuration & Versioning ---
$StackPort = "8888"
$PmaVersion = "5.2.3" # Specify your exact version here
$ProgressPreference = 'SilentlyContinue'

# --- Path Discovery ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent
$PersistDir = Join-Path (Split-Path $AppRoot -Parent) "persist\flowstack"

# Helper Function for PMA
function Ensure-PMA {
    $PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"

    if (!(Test-Path $PmaFolder)) {
        Write-Host ">>> phpMyAdmin $PmaVersion not found. Installing..." -ForegroundColor Yellow

        $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
        $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
        $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

        # 1. Download
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath

        # 2. Fast Extraction using .NET
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempExtract)

        # 3. Move and Rename to exactly 'phpmyadmin'
        $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1
        Move-Item -Path $ExtractedFolder.FullName -Destination $PmaFolder

        # 4. Inject Config
        $Template = Join-Path $AppRoot "core\templates\pma-config.php"
        if (Test-Path $Template) {
            Copy-Item $Template -Destination (Join-Path $PmaFolder "config.inc.php") -Force
        }

        # Cleanup
        Remove-Item $ZipPath -ErrorAction SilentlyContinue
        Remove-Item $TempExtract -Recurse -ErrorAction SilentlyContinue
        Write-Host ">>> phpMyAdmin $PmaVersion Ready!" -ForegroundColor Green
    }
}

# --- Command Router ---
switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Initializing..." -ForegroundColor Cyan
        Ensure-PMA

        # Setup Paths
        $PhpDir = Split-Path (Get-Command php).Source
        $ExtDir = Join-Path $PhpDir "ext"
        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        # Junction for htdocs (Keep this, as it points to your Persist folder)
        $HtdocsLink = Join-Path $AppRoot "core\dashboard\htdocs"
        $ActualHtdocs = Join-Path $PersistDir "htdocs"
        if (!(Test-Path $ActualHtdocs)) { New-Item -ItemType Directory -Path $ActualHtdocs -Force | Out-Null }
        if (!(Test-Path $HtdocsLink)) { New-Item -ItemType Junction -Path $HtdocsLink -Target $ActualHtdocs }

        # Start Services
        Write-Host ">>> Starting MariaDB & PHP Server..." -ForegroundColor Gray
        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        $PhpArgs = @("-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"", "-d", "extension_dir=`"$ExtDir`"")
        Start-Process php -ArgumentList $PhpArgs -WindowStyle Hidden

        Write-Host ">>> FlowStack is UP at http://localhost:$StackPort" -ForegroundColor Green
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        Write-Host ">>> FlowStack: Shutting down..." -ForegroundColor Red
        Get-Process php, mysqld -ErrorAction SilentlyContinue | Stop-Process -Force
        Write-Host ">>> All services stopped." -ForegroundColor Gray
    }

    "new" {
        # Pass the port to the helper script if needed
        & "$PSScriptPath\helpers\new-site.ps1" -Port $StackPort
    }

    Default {
        Write-Host "Usage: flow [up | down | new]" -ForegroundColor White
    }
}