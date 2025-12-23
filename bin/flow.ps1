param([string]$Action)

$StackPort = "8888"
$AppRoot = Split-Path $PSScriptRoot -Parent
$PersistHtdocs = Join-Path $AppRoot "core\dashboard\htdocs"

switch ($Action) {
    "up" {
        Write-Host ">>> FlowStack: Starting Services..." -ForegroundColor Cyan
        Start-Process mysqld -ArgumentList "--console" -WindowStyle Hidden

        $PhpIni = Join-Path $AppRoot "core\templates\php-stack.ini"
        $Router = Join-Path $AppRoot "core\dashboard\router.php"
        Start-Process php -ArgumentList "-S", "localhost:$StackPort", "-t", "`"$AppRoot\core\dashboard`"", "-c", "`"$PhpIni`"", "`"$Router`"" -WindowStyle Hidden

        Write-Host ">>> FlowStack is LIVE at http://localhost:$StackPort" -ForegroundColor Green
    }

    "down" {
        Write-Host ">>> FlowStack: Stopping Services..." -ForegroundColor Yellow
        Stop-Process -Name php, mysqld -Force -ErrorAction SilentlyContinue
        Write-Host ">>> Services Stopped." -ForegroundColor Gray
    }

    "new" {
        $PhpRunning = Get-Process php -ErrorAction SilentlyContinue
        $MysqlRunning = Get-Process mysqld -ErrorAction SilentlyContinue

        if (!$PhpRunning -or !$MysqlRunning) {
            Write-Host ">>> Services not detected. Starting now..." -ForegroundColor Yellow
            & $PSCommandPath "up"
            Write-Host ">>> Waiting for warm-up..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
        & "$PSScriptRoot\helpers\new-site.ps1"
    }

    "list" {
        Write-Host ">>> FlowStack: Installed Websites" -ForegroundColor Cyan
        Write-Host "----------------------------------------"

        # Check if the path exists (even if it's a junction)
        if (Test-Path $PersistHtdocs) {
            # We look for directories inside the htdocs junction
            $Sites = Get-ChildItem -Path "$PersistHtdocs\*" -Directory -ErrorAction SilentlyContinue

            if (!$Sites) {
                Write-Host " No sites found in: $PersistHtdocs" -ForegroundColor Gray
            } else {
                foreach ($Site in $Sites) {
                    Write-Host " - $($Site.Name)" -ForegroundColor White
                    Write-Host "   URL: http://localhost:8888/$($Site.Name)" -ForegroundColor Gray
                }
            }
        } else {
            Write-Host " Error: Path not found ($PersistHtdocs)" -ForegroundColor Red
        }
        Write-Host "----------------------------------------"
    }

    "update-wp" {
        Write-Host ">>> FlowStack: Refreshing WordPress Master Source..." -ForegroundColor Cyan
        & "$PSScriptRoot\helpers\install-wp.ps1" -ForceUpdate
        Write-Host ">>> Master Source is now up to date." -ForegroundColor Green
    }

    "rm" {
        $SiteName = $args[1]
        & "$PSScriptRoot\helpers\remove-site.ps1" $SiteName
    }

    "wp" {
        $PhpIni = Join-Path $AppRoot "core\templates\php-stack.ini"
        $env:PHPRC = $PhpIni
        $wpArgs = $args | Select-Object -Skip 1
        & wp $wpArgs --allow-root
        $env:PHPRC = ""
    }

    Default {
        Write-Host ""
        Write-Host "  FlowStack CLI v1.1.0" -ForegroundColor Cyan
        Write-Host "  ===================="
        Write-Host "  up           : Start MariaDB & PHP Dashboard."
        Write-Host "  down         : Stop all running FlowStack processes."
        Write-Host ""
        Write-Host "  new          : Create a new WP site with a random password."
        Write-Host "  list         : Show all websites currently in htdocs."
        Write-Host "  rm [name]    : Delete a site folder and its database."
        Write-Host ""
        Write-Host "  update-wp    : Download the latest WP version to persist."
        Write-Host "  wp [cmd]     : Run any WP-CLI command (e.g., flowstack wp plugin list)."
        Write-Host ""
        Write-Host "  Sites Path:  " -NoNewline; Write-Host "$PersistHtdocs" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Tip: Use 'flowstack list' to see site names for 'rm'." -ForegroundColor DarkGray
        Write-Host ""
    }
}