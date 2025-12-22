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
# Save where you are right now
$OriginalLocation = Get-Location

Set-Location $DestPath
Write-Host ">>> Configuring Database: $DbName..." -ForegroundColor Gray

# Define the path to your ini (consistent with flow.ps1)
$PhpIni = Join-Path $AppRoot "core\templates\php-stack.ini"

# Tell WP-CLI to use your specific PHP config for these commands
$env:PHPRC = $PhpIni

# 1. Create Database
wp db create --allow-root

# 2. Create Config
wp config create --dbname=$DbName --dbuser=root --dbpass="" --allow-root

# 3. Install WordPress
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="admin" --admin_password="password" --admin_email="admin@localhost.local" --skip-email --allow-root

# Clean up env variable after we are done
$env:PHPRC = ""
Set-Location $OriginalLocation

Write-Host ">>> Site Created! Access it at: http://localhost:8888/$SiteSlug" -ForegroundColor Green