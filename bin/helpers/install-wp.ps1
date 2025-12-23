param([switch]$ForceUpdate)

# --- 1. SET UP PATHS ---
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
$PersistRoot = Join-Path $ScoopRoot "persist\flowstack"

# --- 2. VERSION CHECK ---
Write-Host ">>> Checking for latest WordPress..." -ForegroundColor Gray
try {
    $WpApi = Invoke-RestMethod -Uri "https://api.wordpress.org/core/version-check/1.7/"
    $LatestVersion = $WpApi.offers[0].current
} catch {
    $LatestVersion = "6.7.1" # Fallback
}

$MasterCore = Join-Path $PersistRoot "wordpress-$LatestVersion"

# --- 3. DOWNLOAD LOGIC ---
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

# Output the path so the calling script can use it
return $MasterCore