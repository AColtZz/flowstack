# --- 1. GET THE SOURCE ---
# Call the installer and capture the path it returns
$MasterCore = & "$PSScriptRoot\install-wp.ps1"

if (!(Test-Path $MasterCore)) {
    Write-Host ">>> Error: Could not locate WordPress source." -ForegroundColor Red
    return
}

# --- 2. SET UP PATHS ---
$AppRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"

# --- 3. GET SITE DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $HtdocsPath $SiteSlug
$DbName = $SiteSlug -replace '-','_'

# Automated Credentials
$AdminUser = "Admin"
$AdminEmail = "admin@localhost.com"
$Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*"
$AdminPass = -join ((1..16) | ForEach-Object { $Characters[(Get-Random -Maximum $Characters.Length)] })

# --- 4. DEPLOY FILES ---
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
$env:PHPRC = Join-Path $AppRoot "core\templates\php-stack.ini"

Write-Host ">>> Configuring WordPress with utf8mb4..." -ForegroundColor Gray

# 1. Create Config with explicit Charset
wp config create --dbname=$DbName --dbuser=root --dbpass="" --dbcharset="utf8mb4" --allow-root

# 2. Create Database with explicit Collation (Fixes your issue)
# This forces the database to use the modern WordPress standard
wp db create --db_column_type="utf8mb4_unicode_ci" --allow-root

# 3. Install WordPress
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="$AdminUser" --admin_password="$AdminPass" --admin_email="$AdminEmail" --skip-email --allow-root

# --- 6. SUMMARY ---
Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   WP SITE CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host " User:     $AdminUser"
Write-Host " Email:    $AdminEmail"
Write-Host " Password: $AdminPass" -ForegroundColor Yellow
Write-Host "----------------------------------------"
Write-Host " URL:      http://localhost:8888/$SiteSlug"
Write-Host "========================================`n"

$env:PHPRC = ""
Set-Location $OriginalLocation