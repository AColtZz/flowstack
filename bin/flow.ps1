param([string]$Action, [string]$Value)

# --- Configuration ---
$StackPort = "8888"
$PmaVersion = "5.2.3"
$ProgressPreference = 'SilentlyContinue'

# --- Path Discovery ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent

# Go up 4 levels to reach the Scoop Root (where 'apps' and 'persist' live)
# 1: bin, 2: current/version, 3: flowstack, 4: apps
$ScoopRoot = $PSScriptPath
for ($i=0; $i -lt 4; $i++) { $ScoopRoot = Split-Path $ScoopRoot -Parent }

# Now join back to the persist branch
$PersistDir = Join-Path $ScoopRoot "persist\flowstack"
$ConfigFile = Join-Path $PersistDir "config.json"

# Safety: If we are NOT in a scoop folder, fall back to a local persist folder
if (-not (Test-Path (Split-Path $PersistDir -Parent))) {
    $PersistDir = Join-Path $AppRoot "persist"
}

# --- Setup Detection & Path Loading ---
if (!(Test-Path $PersistDir)) { New-Item -ItemType Directory -Path $PersistDir -Force | Out-Null }

if (Test-Path $ConfigFile) {
    $Config = Get-Content $ConfigFile | ConvertFrom-Json
} else {
    # First-time Setup: Default to Documents/FlowStack/htdocs
    $DefaultPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "FlowStack\htdocs"
    $Config = @{
        UserHtdocs = $DefaultPath
        SetupDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $Config | ConvertTo-Json | Set-Content $ConfigFile
    Write-Host ">>> First run detected! Default workspace: $DefaultPath" -ForegroundColor Yellow
}

# --- Helper: Load Config ---
function Get-FlowConfig {
    if (Test-Path $ConfigFile) {
        return Get-Content $ConfigFile | ConvertFrom-Json
    }
    return $null
}

# Helper Function for PMA
function Ensure-PMA {
    $PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"

    if (!(Test-Path $PmaFolder)) {
        $StatusTitle = "FlowStack Setup: phpMyAdmin $PmaVersion"
        Write-Progress -Activity $StatusTitle -Status "Preparing download..." -PercentComplete 10

        $Url = "https://files.phpmyadmin.net/phpMyAdmin/$PmaVersion/phpMyAdmin-$PmaVersion-all-languages.zip"
        $ZipPath = Join-Path $env:TEMP "pma_$PmaVersion.zip"
        $TempExtract = Join-Path $env:TEMP "pma_temp_extract"

        # 1. Download with manual progress (if file is large, this shows progress)
        Write-Progress -Activity $StatusTitle -Status "Downloading zip from phpmyadmin.net..." -PercentComplete 30
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath

        # 2. Fast Extraction
        Write-Progress -Activity $StatusTitle -Status "Extracting files (Fast .NET Mode)..." -PercentComplete 60
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $TempExtract)

        # 3. Move and Rename
        Write-Progress -Activity $StatusTitle -Status "Moving to dashboard..." -PercentComplete 85
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

        Write-Progress -Activity $StatusTitle -Status "Completed!" -PercentComplete 100
        Start-Sleep -Seconds 1 # Let the user see it's 100%
        Write-Progress -Activity $StatusTitle -Completed

        Write-Host ">>> phpMyAdmin $PmaVersion Ready!" -ForegroundColor Green
    }
}

# --- Command Router ---
switch ($Action) {
    "init" {
        if (-not $Value) {
            Write-Host "Usage: flow init `"C:/Path/To/Your/Projects`"" -ForegroundColor Yellow
            return
        }

        $CleanPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)

        if (!(Test-Path $PersistDir)) { New-Item -ItemType Directory -Path $PersistDir -Force | Out-Null }

        $Config = @{
            UserHtdocs = $CleanPath
            IsConfigured = $true
            SetupDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }

        $Config | ConvertTo-Json | Set-Content $ConfigFile
        Write-Host ">>> FlowStack Initialized!" -ForegroundColor Green
        Write-Host ">>> Projects will live in: $CleanPath" -ForegroundColor Gray
        Write-Host ">>> You can now run 'flow up'" -ForegroundColor Cyan
    }

    "up" {
        $Config = Get-FlowConfig
        if ($null -eq $Config) {
            Write-Host "Error: FlowStack is not initialized." -ForegroundColor Red
            Write-Host "Please run: flow init `"C:/Path/To/Projects`"" -ForegroundColor White
            return
        }

        Write-Host ">>> FlowStack: Initializing..." -ForegroundColor Cyan
        Ensure-PMA

        # Ensure the User's Workspace exists
        if (!(Test-Path $Config.UserHtdocs)) {
            New-Item -ItemType Directory -Path $Config.UserHtdocs -Force | Out-Null
        }

        # Link Dashboard to User Workspace
        $HtdocsLink = Join-Path $AppRoot "core\dashboard\htdocs"
        if (Test-Path $HtdocsLink) { Remove-Item $HtdocsLink -Force }
        New-Item -ItemType Junction -Path $HtdocsLink -Target $Config.UserHtdocs | Out-Null

        # Start Services
        $PhpDir = Split-Path (Get-Command php).Source
        $ExtDir = Join-Path $PhpDir "ext"
        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden
        $PhpArgs = @("-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"", "-d", "extension_dir=`"$ExtDir`"")
        Start-Process php -ArgumentList $PhpArgs -WindowStyle Hidden

        Write-Host ">>> FlowStack is UP at http://localhost:$StackPort" -ForegroundColor Green
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        $Procs = Get-Process php, mysqld -ErrorAction SilentlyContinue
        if ($Procs) {
            Write-Host ">>> Shutting down services..." -ForegroundColor Red
            $Procs | Stop-Process -Force
        } else {
            Write-Host ">>> No services are currently running." -ForegroundColor Gray
        }
    }

    "clear" {
        & $MyInvocation.MyCommand.Path "down"

        $PmaFolder = Join-Path $AppRoot "core\dashboard\phpmyadmin"
        if (Test-Path $PmaFolder) {
            Write-Host ">>> Clearing system files..." -ForegroundColor Yellow
            Remove-Item $PmaFolder -Recurse -Force
            Write-Host ">>> System cleared. (Your project files were kept safe)" -ForegroundColor Green
        } else {
            Write-Host ">>> Nothing to clear." -ForegroundColor Gray
        }
    }

    "new" {
        $Config = Get-FlowConfig
        if ($null -eq $Config) {
            Write-Host "Please run 'flow init' first." -ForegroundColor Red
            return
        }
        & "$PSScriptPath\helpers\new-site.ps1" -Port $StackPort -InstallPath $Config.UserHtdocs
    }

    Default {
        Write-Host "Usage: flow [init | up | down | clear | new]" -ForegroundColor White
        Write-Host "  init <path>  - Setup your project workspace" -ForegroundColor Gray
        Write-Host "  up           - Start the local dev environment" -ForegroundColor Gray
        Write-Host "  down         - Stop all background services" -ForegroundColor Gray
        Write-Host "  clear        - Reset the core system (PMA)" -ForegroundColor Gray
        Write-Host "  new          - Create a new WordPress site" -ForegroundColor Gray
    }
}