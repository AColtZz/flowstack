# --- 1. SET UP PATHS ---
$AppRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Scoop structure: .../apps/flowstack/current -> .../persist/flowstack
$PersistDir = Join-Path (Split-Path (Split-Path $AppRoot -Parent) -Parent) "persist\flowstack"
$MasterCore = Join-Path $AppRoot "core\wordpress-source"

# --- 2. ENSURE SOURCE ---
if (!(Test-Path $MasterCore)) {
    Write-Host ">>> Downloading WordPress..." -ForegroundColor Yellow
    $ZipPath = Join-Path $env:TEMP "wp.zip"
    Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile $ZipPath
    Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\wp-temp" -Force
    Move-Item -Path "$env:TEMP\wp-temp\wordpress" -Destination $MasterCore
    Remove-Item "$env:TEMP\wp-temp" -Recurse -Force
}

# --- 3. GET DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $PersistDir "htdocs\$SiteSlug"

# --- 4. DEPLOY ---
New-Item -ItemType Directory -Path $DestPath -Force | Out-Null
Copy-Item "$MasterCore\*" -Destination $DestPath -Recurse
cd $DestPath
wp config create --dbname=$($SiteSlug -replace '-','_') --dbuser=root --dbpass="" --allow-root
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="admin" --admin_password="password" --admin_email="admin@localhost.local" --skip-email --allow-root