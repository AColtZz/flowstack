param([string]$Action, [string]$Value)

# --- Configuration ---
$StackPort = "8888"
$PmaVersion = "5.2.3"
$ProgressPreference = 'SilentlyContinue'

# --- Path Discovery ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent

# Scoop Structure Discovery
# Expected: .../scoop/apps/flowstack/current/bin/flow.ps1
$ScoopRoot = $PSScriptPath
for ($i=0; $i -lt 4; $i++) { $ScoopRoot = Split-Path $ScoopRoot -Parent }

# Set Persist to: Scoop/persist/flowstack
$PersistDir = Join-Path $ScoopRoot "persist\flowstack"
$UserHtdocs = Join-Path $PersistDir "htdocs"
$ConfigFile = Join-Path $PersistDir "config.json"

# Ensure directories exist immediately
if (!(Test-Path $UserHtdocs)) { New-Item -ItemType Directory -Path $UserHtdocs -Force | Out-Null }

# --- Helper Function for PMA (Can be called via post-install or on 'up') ---
function Ensure-PMA {
    $PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"
    if (!(Test-Path $PmaFolder)) {
        Write-Host ">>> Installing phpMyAdmin $PmaVersion..." -ForegroundColor Cyan

        $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
        $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
        $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

        Invoke-WebRequest -Uri $Url -OutFile $ZipPath

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempExtract)

        $ExtractedFolder = Get-ChildItem $TempExtract | Select-Object -First 1
        Move-Item -Path $ExtractedFolder.FullName -Destination $PmaFolder

        # Inject Config Template
        $Template = Join-Path $AppRoot "core\templates\pma-config.php"
        if (Test-Path $Template) {
            Copy-Item $Template -Destination (Join-Path $PmaFolder "config.inc.php") -Force
        }

        Remove-Item $ZipPath, $TempExtract -Recurse -ErrorAction SilentlyContinue
        Write-Host ">>> phpMyAdmin Ready!" -ForegroundColor Green
    }
}

# --- Command Router ---
switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services..." -ForegroundColor Cyan

        # 1. Ensure PMA is there
        Ensure-PMA

        # 2. Junction Link: Link Scoop/apps/.../dashboard/htdocs -> Scoop/persist/.../htdocs
        $DashboardHtdocs = Join-Path $AppRoot "core\dashboard\htdocs"
        if (Test-Path $DashboardHtdocs) {
            # Remove existing link/folder to ensure it points to the right persist location
            Remove-Item $DashboardHtdocs -Recurse -Force
        }
        New-Item -ItemType Junction -Path $DashboardHtdocs -Target $UserHtdocs | Out-Null

        # 3. Start MySQL and PHP
        $PhpDir = Split-Path (Get-Command php).Source
        $ExtDir = Join-Path $PhpDir "ext"
        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        $PhpArgs = @("-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"", "-d", "extension_dir=`"$ExtDir`"")
        Start-Process php -ArgumentList $PhpArgs -WindowStyle Hidden

        Write-Host ">>> FlowStack is LIVE at http://localhost:$StackPort" -ForegroundColor Green
        Write-Host ">>> Files: $UserHtdocs" -ForegroundColor Gray
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        $Procs = Get-Process php, mysqld -ErrorAction SilentlyContinue
        if ($Procs) {
            Write-Host ">>> Shutting down services..." -ForegroundColor Red
            $Procs | Stop-Process -Force
        }
    }

    "new" {
        & "$PSScriptPath\helpers\new-site.ps1" -Port $StackPort -InstallPath $UserHtdocs
    }

    "pma-setup" {
        Ensure-PMA
    }

    Default {
        Write-Host "Usage: flow [up | down | new | pma-setup]" -ForegroundColor White
        Write-Host "  up        - Start services & link persist htdocs" -ForegroundColor Gray
        Write-Host "  down      - Stop services" -ForegroundColor Gray
        Write-Host "  new       - Create a new site in persist/htdocs" -ForegroundColor Gray
        Write-Host "  pma-setup - Manually trigger phpMyAdmin download" -ForegroundColor Gray
    }
}