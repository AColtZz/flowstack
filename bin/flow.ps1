param([string]$Action)

# 1. Path Discovery
$PSScriptPath = Split-Path $MyInvocation.MyCommand.Path
$AppRoot = Split-Path $PSScriptPath -Parent
$PersistDir = Join-Path (Split-Path $AppRoot -Parent) "persist\flowstack"
$ConfigPath = Join-Path $PersistDir "stack-config.json"

# 2. Command Router
switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services" -ForegroundColor Cyan

        # This creates a 'tunnel' so localhost:8080/htdocs points to your actual sites
        $HtdocsLink = Join-Path $AppRoot "core\dashboard\htdocs"
        $ActualHtdocs = Join-Path $PersistDir "htdocs"

        if (!(Test-Path $ActualHtdocs)) { New-Item -ItemType Directory -Path $ActualHtdocs | Out-Null }

        if (!(Test-Path $HtdocsLink)) {
            New-Item -ItemType Junction -Path $HtdocsLink -Target $ActualHtdocs
        }

        # Start MariaDB & PHP
        Start-Process mysqld -ArgumentList "--console" -NoNewWindow
        Start-Process php -ArgumentList "-S localhost:8080 -t `"$AppRoot\core\dashboard`"" -NoNewWindow

        Write-Host ">>> Stack is UP!" -ForegroundColor Green
        Start-Process "http://localhost:8080"
    }

    "new" {
        # Check if config exists, if not run setup
        & "$PSScriptPath\helpers\new-site.ps1"
    }

    "pma" {
        $PmaPath = Join-Path $AppRoot "core\dashboard\phpmyadmin"

        if (!(Test-Path $PmaPath)) {
            Write-Host ">>> phpMyAdmin not found. Installing..." -ForegroundColor Yellow

            # 1. Download latest PMA
            $ZipPath = Join-Path $env:TEMP "pma-latest.zip"
            $DownloadUrl = "https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath

            # 2. Extract
            Write-Host ">>> Extracting..." -ForegroundColor Gray
            Expand-Archive -Path $ZipPath -DestinationPath (Join-Path $env:TEMP "pma-temp") -Force

            # 3. Move and Cleanup (PMA zip has a versioned subfolder)
            $ExtractedFolder = Get-ChildItem (Join-Path $env:TEMP "pma-temp") | Select-Object -First 1
            Move-Item -Path $ExtractedFolder.FullName -Destination $PmaPath

            # 4. Inject your custom config template
            $TemplateConfig = Join-Path $AppRoot "core\templates\pma-config.php"
            $DestConfig = Join-Path $PmaPath "config.inc.php"
            Copy-Item $TemplateConfig -Destination $DestConfig -Force

            Remove-Item $ZipPath
            Remove-Item (Join-Path $env:TEMP "pma-temp") -Recurse
            Write-Host ">>> phpMyAdmin installed successfully!" -ForegroundColor Green
        }

        Write-Host "Opening phpMyAdmin..." -ForegroundColor Cyan
        Start-Process "http://localhost:8080/phpmyadmin"
    }

    Default {
        Write-Host "Usage: flow [up | new | pma | dash]" -ForegroundColor White
        Write-Host "  up   - Start services" -ForegroundColor Gray
        Write-Host "  new  - Create a new WP site" -ForegroundColor Gray
        Write-Host "  pma  - Open phpMyAdmin" -ForegroundColor Gray
    }
}