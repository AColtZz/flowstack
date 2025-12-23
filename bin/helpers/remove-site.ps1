param([string]$SiteSlug)

# --- 1. SETUP ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"

# --- NEW: SERVICE CHECK ---
$MysqlRunning = Get-Process mysqld -ErrorAction SilentlyContinue
if (!$MysqlRunning) {
    Write-Host ">>> Error: MariaDB is not running! Start it with 'flowstack up' first." -ForegroundColor Red
    return
}

# Only ask if the user didn't provide it in the command
if ([string]::IsNullOrWhiteSpace($SiteSlug)) {
    $SiteSlug = Read-Host "Enter the name of the site to remove"
}

$DestPath = Join-Path $HtdocsPath $SiteSlug
$DbName = $SiteSlug -replace '-','_'

if (!(Test-Path $DestPath)) {
    Write-Host ">>> Error: Site '$SiteSlug' not found at $DestPath" -ForegroundColor Red
    return
}

# --- 2. CONFIRMATION ---
Write-Host "Preparing to remove: $SiteSlug" -ForegroundColor Yellow
$ConfirmFiles = Read-Host "Are you sure you want to delete the FILES? (y/n)"
if ($ConfirmFiles -ne 'y') { Write-Host ">>> Aborted."; return }

$ConfirmDb = Read-Host "Do you also wish to remove the database '$DbName'? (y/n) [default: y]"
$DeleteDb = ($null -eq $ConfirmDb -or $ConfirmDb -eq "" -or $ConfirmDb -eq "y")

# --- 3. EXECUTION ---
if ($DeleteDb) {
    Write-Host ">>> Dropping Database: $DbName..." -ForegroundColor Gray

    # IMPORTANT: Ensure the environment variable is set for this specific process
    $env:PHPRC = Join-Path $AppRoot "core\templates\php-stack.ini"

    Set-Location $DestPath

    # We add a small retry loop or a brief sleep if it just started
    # but usually, the explicit PHPRC and --allow-root is enough.
    wp db drop --yes --allow-root

    $env:PHPRC = ""
    Set-Location $AppRoot
}

Write-Host ">>> Deleting Files..." -ForegroundColor Gray
Remove-Item $DestPath -Recurse -Force

Write-Host ">>> Site '$SiteSlug' has been removed." -ForegroundColor Green