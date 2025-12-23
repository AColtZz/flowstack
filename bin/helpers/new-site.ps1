param(
    [switch]$ForceUpdate # Use 'flowstack new -ForceUpdate' to redownload source
)

# --- 1. SET UP PATHS ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"

# NEW: Target the persist folder for the master source
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
$PersistRoot = Join-Path $ScoopRoot "persist\flowstack"

# --- 2. VERSION CHECK & SOURCE SETUP ---
Write-Host ">>> Checking for latest WordPress version..." -ForegroundColor Gray
try {
    # Fetch the latest version string from WordPress API
    $WpApi = Invoke-RestMethod -Uri "https://api.wordpress.org/core/version-check/1.7/"
    $LatestVersion = $WpApi.offers[0].current
} catch {
    $LatestVersion = "6.9" # Fallback if offline
}

$MasterCore = Join-Path $PersistRoot "wordpress-$LatestVersion"

# Check if we need to download
if (!(Test-Path $MasterCore) -or $ForceUpdate) {
    Write-Host ">>> Downloading WordPress $LatestVersion to Persist..." -ForegroundColor Yellow

    $ZipPath = Join-Path $env:TEMP "wp-$LatestVersion.zip"
    $TempExtract = Join-Path $env:TEMP "wp-temp"

    Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile $ZipPath

    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force

    # Ensure persist root exists
    if (!(Test-Path $PersistRoot)) { New-Item -ItemType Directory -Path $PersistRoot -Force | Out-Null }

    # Remove old version if forcing update
    if (Test-Path $MasterCore) { Remove-Item $MasterCore -Recurse -Force }

    Move-Item -Path "$TempExtract\wordpress" -Destination $MasterCore
    Remove-Item $ZipPath, $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ">>> WordPress $LatestVersion stored in persist." -ForegroundColor Green
} else {
    Write-Host ">>> Using existing WordPress $LatestVersion source from Persist." -ForegroundColor Cyan
}

# --- 3. GET DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $HtdocsPath $SiteSlug
$DbName = $SiteSlug -replace '-','_' # Keep your preferred underscore naming

# --- 4. DEPLOY ---
if (Test-Path $DestPath) {
    Write-Host ">>> Error: Site '$SiteSlug' already exists!" -ForegroundColor Red
    return
}

Write-Host ">>> Creating site at $DestPath..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
Copy-Item "$MasterCore\*" -Destination $DestPath -Recurse

# --- 5. WP-CLI SETUP ---
$OriginalLocation = Get-Location
Set-Location $DestPath

# Set PHPRC so WP-CLI finds mysqli in your template
$PhpIni = Join-Path $AppRoot "core\templates\php-stack.ini"
$env:PHPRC = $PhpIni

Write-Host ">>> Configuring WordPress..." -ForegroundColor Gray

# Create config first, then DB, then Install
wp config create --dbname=$DbName --dbuser=root --dbpass="" --allow-root
wp db create --allow-root
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="admin" --admin_password="password" --admin_email="admin@localhost.local" --skip-email --allow-root

# --- 6. CLEANUP ---
$env:PHPRC = ""
Set-Location $OriginalLocation

Write-Host ">>> Site Created! Access it at: http://localhost:8888/$SiteSlug" -ForegroundColor Green