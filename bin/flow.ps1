param([string]$Action)

$StackPort = "8888"
$AppRoot = Split-Path $PSScriptRoot -Parent

$ScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$HOME\scoop" }
$PersistHtdocs = "$ScoopRoot\persist\flowstack\htdocs"

switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services..." -ForegroundColor Cyan
        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        $PhpIni = Join-Path $AppRoot "core\templates\php-stack.ini"
        $Router = Join-Path $AppRoot "core\dashboard\router.php"
        Start-Process php -ArgumentList "-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$PhpIni`"", "`"$Router`"" -WindowStyle Hidden

        Write-Host ">>> FlowStack is LIVE at http://localhost:$StackPort" -ForegroundColor Green
        Start-Process "http://localhost:$StackPort"
    }

    "down" {
        Write-Host ">>> FlowStack: Stopping Services..." -ForegroundColor Yellow
        Stop-Process -Name php, mysqld -Force -ErrorAction SilentlyContinue
        Write-Host ">>> Services Stopped." -ForegroundColor Gray
    }

    "new" {
        # --- NEW: SAFETY CHECK ---
        $PhpRunning = Get-Process php -ErrorAction SilentlyContinue
        $MysqlRunning = Get-Process mysqld -ErrorAction SilentlyContinue

        if (!$PhpRunning -or !$MysqlRunning) {
            Write-Host ">>> Warning: Services are not running!" -ForegroundColor Yellow
            $Choice = Read-Host "Start FlowStack services now? (y/n)"
            if ($Choice -eq 'y') {
                & $PSCommandPath "up"
                Write-Host ">>> Waiting for services to warm up..." -ForegroundColor Gray
                Start-Sleep -Seconds 2 # Give MariaDB a moment to initialize
            } else {
                Write-Host ">>> Aborting: WP-CLI requires an active MariaDB connection." -ForegroundColor Red
                return
            }
        }

        # Run your WordPress site creator helper script
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
    }
}