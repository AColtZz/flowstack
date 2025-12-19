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

        # This creates a 'tunnel' so localhost:8888/htdocs points to your actual sites
        $HtdocsLink = Join-Path $AppRoot "core\dashboard\htdocs"
        $ActualHtdocs = Join-Path $PersistDir "htdocs"

        if (!(Test-Path $ActualHtdocs)) { New-Item -ItemType Directory -Path $ActualHtdocs | Out-Null }

        if (!(Test-Path $HtdocsLink)) {
            New-Item -ItemType Junction -Path $HtdocsLink -Target $ActualHtdocs
        }

        # Start MariaDB & PHP
        Start-Process mysqld -ArgumentList "--console" -NoNewWindow
        Start-Process php -ArgumentList "-S localhost:8888 -t `"$AppRoot\core\dashboard`"" -NoNewWindow

        Write-Host ">>> Stack is UP!" -ForegroundColor Green
        Start-Process "http://localhost:8888"
    }

    "down" {
        Stop-Process -Name php -ErrorAction SilentlyContinue
        Stop-Process -Name mysqld -ErrorAction SilentlyContinue
    }

    "new" {
        # Check if config exists, if not run setup
        & "$PSScriptPath\helpers\new-site.ps1"
    }

    "pma" {
        $PmaPath = Join-Path $AppRoot "core\dashboard\phpmyadmin"

        if (!(Test-Path $PmaPath)) {
            Write-Host ">>> phpMyAdmin not found. Downloading..." -ForegroundColor Yellow
            $ZipPath = Join-Path $env:TEMP "pma.zip"
            # Direct link to the latest stable version
            Invoke-WebRequest -Uri "https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.zip" -OutFile $ZipPath

            Write-Host ">>> Extracting..." -ForegroundColor Gray
            Expand-Archive -Path $ZipPath -DestinationPath "$env:TEMP\pma_temp" -Force

            # PMA zip contains a subfolder like "phpMyAdmin-5.2.1-all-languages"
            $ExtractedFolder = Get-ChildItem "$env:TEMP\pma_temp" | Select-Object -First 1
            Move-Item -Path $ExtractedFolder.FullName -Destination $PmaPath

            # Inject your template config
            $Template = Join-Path $AppRoot "core\templates\pma-config.php"
            if (Test-Path $Template) {
                Copy-Item $Template -Destination (Join-Path $PmaPath "config.inc.php") -Force
            }

            # Cleanup
            Remove-Item $ZipPath
            Remove-Item "$env:TEMP\pma_temp" -Recurse
            Write-Host ">>> phpMyAdmin installed!" -ForegroundColor Green
        }

        Start-Process "http://localhost:8888/phpmyadmin/index.php"
    }

    Default {
        Write-Host "Usage: flow [up | new | pma | dash]" -ForegroundColor White
        Write-Host "  up   - Start services" -ForegroundColor Gray
        Write-Host "  new  - Create a new WP site" -ForegroundColor Gray
        Write-Host "  pma  - Open phpMyAdmin" -ForegroundColor Gray
    }
}