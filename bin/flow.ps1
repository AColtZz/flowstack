param([string]$Action)

$StackPort = "8888"
# AppRoot is the folder where FlowStack is installed (e.g., .../scoop/apps/flowstack/current)
$AppRoot = Split-Path $PSScriptRoot -Parent

# Dynamic Scoop Path Detection for the Help Menu
$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
$PersistHtdocs = "$ScoopRoot\persist\flowstack\htdocs"

switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services..." -ForegroundColor Cyan

        $CustomIni = Join-Path $AppRoot "core\templates\php-stack.ini"

        # 1. Start MariaDB (mysqld)
        # Using --console to keep it lightweight; WindowStyle Hidden keeps it out of your taskbar
        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        # 2. Start PHP Dashboard
        # -S: Local server | -t: Document Root | -c: Custom php.ini
        Start-Process php -ArgumentList "-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$CustomIni`"" -WindowStyle Hidden

        Write-Host ">>> FlowStack is LIVE at http://localhost:$StackPort" -ForegroundColor Green
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        Write-Host ">>> FlowStack: Stopping Services..." -ForegroundColor Yellow
        # Force stop the processes; SilentlyContinue prevents errors if they aren't running
        Stop-Process -Name php, mysqld -Force -ErrorAction SilentlyContinue
        Write-Host ">>> Services Stopped." -ForegroundColor Gray
    }

    "new" {
        # Runs your WordPress site creator helper script
        & "$PSScriptRoot\helpers\new-site.ps1"
    }

    Default {
        Write-Host ""
        Write-Host "  FlowStack CLI v1.0.0" -ForegroundColor Cyan
        Write-Host "  --------------------"
        Write-Host "  up      : Start MariaDB, PHP Dashboard, and open browser."
        Write-Host "  down    : Kill all running PHP and MySQL processes."
        Write-Host "  new     : Launch the WordPress Site Creator wizard."
        Write-Host ""
        Write-Host "  Your websites are stored in:" -ForegroundColor White
        Write-Host "  $PersistHtdocs" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Tip: Use 'flowstack up' to get started." -ForegroundColor DarkGray
        Write-Host ""
    }
}