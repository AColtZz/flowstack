# --- 1. SET UP PATHS ---
$AppRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$PersistDir = Join-Path (Split-Path $AppRoot -Parent) "persist\flowstack"
$MasterCore = Join-Path $AppRoot "core\wordpress-source"

# --- 2. ENSURE WORDPRESS SOURCE EXISTS ---
if (!(Test-Path $MasterCore)) {
    Write-Host ">>> WordPress source not found. Downloading latest..." -ForegroundColor Yellow
    $ZipPath = Join-Path $env:TEMP "wp-latest.zip"
    Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile $ZipPath

    Write-Host ">>> Extracting..." -ForegroundColor Gray
    Expand-Archive -Path $ZipPath -DestinationPath (Join-Path $env:TEMP "wp-temp") -Force

    # Move from 'wordpress' subfolder to our MasterCore
    Move-Item -Path "$(Join-Path $env:TEMP "wp-temp\wordpress")" -Destination $MasterCore
    Remove-Item $ZipPath
    Remove-Item "$(Join-Path $env:TEMP "wp-temp")" -Recurse
}

# --- 3. GET SITE DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $PersistDir "htdocs\$SiteSlug"

if (Test-Path $DestPath) { Write-Warning "Site already exists!"; return }

# --- 4. DEPLOY & INSTALL ---
Write-Host ">>> Deploying WordPress to $DestPath..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $DestPath | Out-Null

# Full copies for stability
Copy-Item "$MasterCore\*" -Destination $DestPath -Recurse

# Create Database via MariaDB
$DBName = $SiteSlug.Replace("-", "_") # DBs prefer underscores
Write-Host ">>> Creating Database: $DBName" -ForegroundColor Green
echo "CREATE DATABASE \`$DBName\`;" | mysql -u root

# WP-CLI Install
cd $DestPath
wp config create --dbname=$DBName --dbuser=root --dbpass="" --allow-root
wp core install --url="http://localhost:8080/$SiteSlug" --title="$SiteName" --admin_user="admin" --admin_password="password" --admin_email="admin@localhost.local" --skip-email --allow-root

# Force ABSPATH fix for your specific stack architecture
(Get-Content wp-config.php) -replace "if \( ! defined\( 'ABSPATH' \) \)", "" -replace "define\( 'ABSPATH', __DIR__ . '/' \);", "define( 'ABSPATH', __DIR__ . '/' );" | Set-Content wp-config.php

Write-Host ">>> SUCCESS! Live at http://localhost:8080/$SiteSlug" -ForegroundColor Green
Start-Process "http://localhost:8080/$SiteSlug/wp-admin"