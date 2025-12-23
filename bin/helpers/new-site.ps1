param(
    [switch]$ForceUpdate
)

# --- 1. SET UP PATHS ---
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path (Split-Path $PSScriptPath -Parent) -Parent
$HtdocsPath = Join-Path $AppRoot "core\dashboard\htdocs"
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
$PersistRoot = Join-Path $ScoopRoot "persist\flowstack"

# --- 2. VERSION CHECK & SOURCE SETUP ---
Write-Host ">>> Checking for latest WordPress version..." -ForegroundColor Gray
try {
    $WpApi = Invoke-RestMethod -Uri "https://api.wordpress.org/core/version-check/1.7/"
    $LatestVersion = $WpApi.offers[0].current
} catch {
    $LatestVersion = "6.9"
}

$MasterCore = Join-Path $PersistRoot "wordpress-$LatestVersion"

if (!(Test-Path $MasterCore) -or $ForceUpdate) {
    Write-Host ">>> Downloading WordPress $LatestVersion to Persist..." -ForegroundColor Yellow
    $ZipPath = Join-Path $env:TEMP "wp-$LatestVersion.zip"
    $TempExtract = Join-Path $env:TEMP "wp-temp"
    Invoke-WebRequest -Uri "https://wordpress.org/latest.zip" -OutFile $ZipPath
    if (Test-Path $TempExtract) { Remove-Item $TempExtract -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempExtract -Force
    if (!(Test-Path $PersistRoot)) { New-Item -ItemType Directory -Path $PersistRoot -Force | Out-Null }
    if (Test-Path $MasterCore) { Remove-Item $MasterCore -Recurse -Force }
    Move-Item -Path "$TempExtract\wordpress" -Destination $MasterCore
    Remove-Item $ZipPath, $TempExtract -Recurse -Force -ErrorAction SilentlyContinue
}

# --- 3. GET DETAILS ---
$SiteName = Read-Host "Enter Site Name"
$SiteSlug = $SiteName.ToLower() -replace '[^a-z0-9-]', '-'
$DestPath = Join-Path $HtdocsPath $SiteSlug
$DbName = $SiteSlug -replace '-','_'

# NEW: Automated Credentials
$AdminUser = "Admin"
$AdminEmail = "admin@localhost.com"
# Generate a 16-character random password
$Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#%^&*"
$AdminPass = -join ((1..16) | ForEach-Object { $Characters[(Get-Random -Maximum $Characters.Length)] })

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
$env:PHPRC = Join-Path $AppRoot "core\templates\php-stack.ini"

Write-Host ">>> Configuring WordPress..." -ForegroundColor Gray
wp config create --dbname=$DbName --dbuser=root --dbpass="" --allow-root
wp db create --allow-root
wp core install --url="http://localhost:8888/$SiteSlug" --title="$SiteName" --admin_user="$AdminUser" --admin_password="$AdminPass" --admin_email="$AdminEmail" --skip-email --allow-root

# --- 6. COMPLETION SUMMARY ---
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "   WP SITE CREATED SUCCESSFULLY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Magenta
Write-Host " User:     $AdminUser"
Write-Host " Email:    $AdminEmail"
Write-Host " Password: $AdminPass" -ForegroundColor Yellow
Write-Host "----------------------------------------"
Write-Host " Directory: $DestPath"
Write-Host ""
Write-Host " To change the password later, run:" -ForegroundColor Gray
Write-Host " flowstack wp user update $AdminUser --user_pass='NEW_PASSWORD'" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

$env:PHPRC = ""
Set-Location $OriginalLocation