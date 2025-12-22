# --- 1. SET UP PATHS ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
# Points to .../scoop/apps/flowstack/current
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent

# Target the junctioned folder inside the dashboard
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"
$MasterCore = Join-Path $AppRoot "core\wordpress-source"

# --- 2. ENSURE SOURCE ---
if (!(Test-Path $MasterCore)) {
    Write-Host ">>> Downloading WordPress Master Source..." -ForegroundColor Yellow
    $ZipPath = Join-Path $env:TEMP "wp.zip"
    $TempExtract = Join-Path $env:TEMP "wp-temp"

    Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile $ZipPath
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }

    Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force
    Move-Item -Path "$TempExtract\wordpress" -Destination $MasterCore

    Remove-Item $ZipPath, $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 3. GET DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $HtdocsPath $SiteSlug
$DbName = $SiteSlug -replace '-','_'

# --- 4. DEPLOY ---
if (Test-Path $DestPath) {
    Write-Host ">>> Error: Site '$SiteSlug' already exists!" -ForegroundColor Red
    return
}

Write-Host ">>> Creating site at $DestPath..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
Copy-Item "$MasterCore\*" -Destination $DestPath -Recurse

# --- 5. WP-CLI SETUP ---
Set-Location $DestPath
Write-Host ">>> Configuring Database: $DbName..." -ForegroundColor Gray

# Create Database first (WP-CLI can do this!)
wp db create --allow-root

wp config create --dbname=$DbName --dbuser=root --dbpass="" --allow-root
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="admin" --admin_password="password" --admin_email="admin@localhost.local" --skip-email --allow-root

Write-Host ">>> Site Created! Access it at: http://localhost:8888/$SiteSlug" -ForegroundColor Green