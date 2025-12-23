param([string]$SiteSlug)

# --- 1. SETUP ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"

# If no slug was passed as an argument, ask for it
if (!$SiteSlug) {
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

# Default to 'y' if user just hits Enter
$ConfirmDb = Read-Host "Do you also wish to remove the database '$DbName'? (y/n) [default: y]"
if ($null -eq $ConfirmDb -or $ConfirmDb -eq "" -or $ConfirmDb -eq "y") {
    $DeleteDb = $true
} else {
    $DeleteDb = $false
}

# --- 3. EXECUTION ---
if ($DeleteDb) {
    Write-Host ">>> Dropping Database: $DbName..." -ForegroundColor Gray
    $env:PHPRC = Join-Path $AppRoot "core\templates\php-stack.ini"

    # Use WP-CLI from inside the folder to drop the DB
    Set-Location $DestPath
    wp db drop --yes --allow-root

    $env:PHPRC = ""
    Set-Location $AppRoot
}

Write-Host ">>> Deleting Files..." -ForegroundColor Gray
Remove-Item $DestPath -Recurse -Force

Write-Host ">>> Site '$SiteSlug' has been removed." -ForegroundColor Green